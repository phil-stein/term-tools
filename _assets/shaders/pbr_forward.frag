#version 460 core

out vec4 FragColor;

// lights
struct point_light_t
{
  vec3  pos;
  vec3  color;
  float intensity;
};

struct dir_light_t
{
  vec3 direction;
  vec3 color;

  int shadow_idx;

};

// in vec2 uv_coords;

// in vec2 TexCoords;
// in vec3 WorldPos;
// in vec3 Normal;
in VS_OUT
{
  vec2 uv_coords;
  vec3 frag_pos;
  vec3 normal;
  mat3 TBN;
} _in;

uniform sampler2D albedo_map;
uniform vec3 tint;

uniform sampler2D normal_map;

uniform sampler2D roughness_map;
uniform float     roughness_f;

uniform sampler2D metallic_map;
uniform float     metallic_f;

uniform sampler2D emissive_map;
uniform float     emissive_f;

uniform vec2 uv_tile;

uniform vec3 view_pos;

uniform samplerCube irradiance_map;
uniform samplerCube prefilter_map;
uniform sampler2D   brdf_lut;
uniform float       cube_map_intensity; 

uniform int point_lights_len;
uniform point_light_t point_lights[8];

uniform int dir_lights_len;
uniform dir_light_t dir_lights[2];

const float PI = 3.14159265359;

float distribution_ggx(vec3 N, vec3 H, float _roughness);
float geometry_schlick_ggx(float NdotV, float _roughness);
float geometry_smith(vec3 N, vec3 V, vec3 L, float _roughness);
vec3  fresnel_schlick(float cos_theta, vec3 F0);
vec3  fresnel_schlick_roughness(float cosTheta, vec3 F0, float roughness);

vec3  calc_directional_light(dir_light_t light, vec3 albedo, vec3 position, vec3 norm, float roughness, float metallic, vec3 F0);

// ----------------------------------------------------------------------------
void main()
{		
  // material properties
  vec2  uv        = _in.uv_coords * uv_tile; 
  float metallic  = texture(metallic_map, uv).r * metallic_f;
  float roughness = texture(roughness_map, uv).r * roughness_f;
  float emissive  = (texture(emissive_map,  uv).r + texture(emissive_map,  uv).g + texture(emissive_map,  uv).b) * 0.75 * emissive_f; // no idea why 0.75, shouldnt it be 0.333, cause /3 u know, idk works though
  // vec3  albedo    = pow(texture(albedo_map, uv).rgb, vec3(2.2));
  //
  vec3 albedo     = ( texture(albedo_map, uv).rgb * tint * clamp(emissive + 1.0, 0.0, 1.0)) + ( texture(emissive_map,  uv).rgb * max(emissive, 0.0));
  // vec3  albedo    = texture(albedo_map, uv).rgb * tint;
  // float ao = texture(aoMap, uv).r;

  // input lighting data
  // also store the per-fragment normals into the gbuffer
  vec3 normal;
  if (texture(normal_map, uv).rgb == vec3(1.0, 1.0, 1.0))
  {
    // normal = vec4(normalize(_in.normal), 1.0);
    normal = normalize(_in.normal);
  }
  else
  {
    normal = texture(normal_map, uv).rgb;
    normal = normalize(normal * 2.0 - 1.0);
    normal = normalize(_in.TBN * normal);
  }
  vec3 N = normalize(normal);
  vec3 V = normalize(view_pos - _in.frag_pos);
  vec3 R = reflect(-V, N); 

  // calculate reflectance at normal incidence; if dia-electric (like plastic) use F0 
  // of 0.04 and if it's a metal, use the albedo color as F0 (metallic workflow)    
  vec3 F0 = vec3(0.04); 
  F0 = mix(F0, albedo, metallic);

  // reflectance equation
  vec3 Lo = vec3(0.0);
  for (int i = 0; i < point_lights_len; ++i)
  {
    // calculate per-light radiance
    vec3  L = normalize(point_lights[i].pos - _in.frag_pos);
    vec3  H = normalize(V + L);
    float distance    = length(point_lights[i].pos - _in.frag_pos);
    float attenuation = point_lights[i].intensity / (distance * distance);
    vec3  radiance   = point_lights[i].color * attenuation;        

    // cook-torrance brdf
    float NDF = distribution_ggx(N, H, roughness);        
    float G   = geometry_smith(N, V, L, roughness);      
    vec3  F   = fresnel_schlick(max(dot(H, V), 0.0), F0);       

    vec3 kS = F;
    vec3 kD = vec3(1.0) - kS;
    kD *= 1.0 - metallic;	  

    vec3  numerator   = NDF * G * F;
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
    vec3  specular    = numerator / denominator;  

    // add to outgoing radiance Lo
    float NdotL = max(dot(N, L), 0.0);                
    Lo += (kD * albedo / PI + specular) * radiance * NdotL; 
  } 
  for (int i = 0; i < dir_lights_len; ++i)
  {
    Lo += calc_directional_light(dir_lights[i], albedo, _in.frag_pos, normal, roughness, metallic, F0); 
  }
  // bc. not making shadow map this cancelles all lighting
  // Lo *= texture(shadow, uv_coords).r;

  // ambient ---------------------------------------------
  // ambient lighting (we now use IBL as the ambient term)
  vec3 F = fresnel_schlick_roughness(max(dot(N, V), 0.0), F0, roughness);
  
  vec3 kS = F;
  vec3 kD = 1.0 - kS;
  kD *= 1.0 - metallic;    

  vec3 irradiance = texture(irradiance_map, -N).rgb;  // -N to flip
  vec3 diffuse      = irradiance * albedo;

  // sample both the pre-filter map and the BRDF lut and combine them together as per the Split-Sum approximation to get the IBL specular part.
  const float MAX_REFLECTION_LOD = 4.0;
  vec3 prefiltered_color = textureLod(prefilter_map, -R,  roughness * MAX_REFLECTION_LOD).rgb; // -R to flip reflection 
  vec2 brdf  = texture(brdf_lut, vec2(max(dot(N, V), 0.0), roughness)).rg;
 
  // // @NOTE: trying without frenel
  // vec3 specular = prefiltered_color * (F* brdf.x + brdf.y);
  // sample both the pre-filter map and the BRDF lut and combine them together as per the Split-Sum approximation to get the IBL specular part.
  vec3 specular = prefiltered_color * (F * brdf.x + brdf.y);

  vec3 ambient = (kD * diffuse + specular) * 0.3 * cube_map_intensity; //  * ao;

  vec3 col = ambient + Lo;

  FragColor = vec4(col, texture(albedo_map, uv).a);
  
  // vec4 _col = ( vec4(col, 1.0) * min(emissive - 1.0, 0.0)) + ( vec4(albedo, 1.0) * emissive);
  // FragColor = vec4(_col.xyz, 1.0);
}

vec3 calc_directional_light(dir_light_t light, vec3 albedo, vec3 position, vec3 norm, float roughness, float metallic, vec3 F0)
{
  vec3 L, V, H, Ir;
  float NoL, NoV, NoH, LoH;

  L = light.direction;
  vec3 radiance = light.color;

  // test if light hitting at below 90 degree angle
  NoL = dot(norm, L);
  if (NoL <= 0.0) { return vec3(0.0); }

  V = normalize(view_pos - position); // maybe view_dir
  H = normalize(V + L);

  // cook-torrance brdf
  float NDF = distribution_ggx(norm, H, roughness);        
  float G   = geometry_smith(norm, V, L, roughness);      
  vec3  F   = fresnel_schlick(max(dot(H, V), 0.0), F0);       

  vec3 kS = F;
  vec3 kD = vec3(1.0) - kS;
  kD *= 1.0 - metallic;	  

  vec3  numerator   = NDF * G * F;
  float denominator = 4.0 * max(dot(norm, V), 0.0) * max(dot(norm, L), 0.0) + 0.0001;
  vec3  specular    = numerator / denominator;  

  // add to outgoing radiance Lo
  float NdotL = max(dot(norm, L), 0.0);                
  return (kD * albedo / PI + specular) * radiance * NdotL;  
}

vec3 fresnel_schlick(float cos_theta, vec3 F0)
{
  return F0 + (1.0 - F0) * pow( clamp( 1.0 - cos_theta, 0.0, 1.0), 5.0);
}
vec3 fresnel_schlick_roughness(float cosTheta, vec3 F0, float roughness)
{
  return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
} 

float distribution_ggx(vec3 N, vec3 H, float _roughness)
{
  float a      = _roughness * _roughness;
  float a2     = a * a;
  float NdotH  = max(dot(N, H), 0.0);
  float NdotH2 = NdotH * NdotH;

  float num   = a2;
  float denom = (NdotH2 * (a2 - 1.0) + 1.0);
  denom = PI * denom * denom;

  return num / denom;
}

float geometry_schlick_ggx(float NdotV, float _roughness)
{
  float r = (_roughness + 1.0);
  float k = (r * r) / 8.0;

  float num   = NdotV;
  float denom = NdotV * (1.0 - k) + k;

  return num / denom;
}

float geometry_smith(vec3 N, vec3 V, vec3 L, float _roughness)
{
  float NdotV = max(dot(N, V), 0.0);
  float NdotL = max(dot(N, L), 0.0);
  float ggx2  = geometry_schlick_ggx(NdotV, _roughness);
  float ggx1  = geometry_schlick_ggx(NdotL, _roughness);

  return ggx1 * ggx2;
}

