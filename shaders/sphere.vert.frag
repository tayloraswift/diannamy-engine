#version 330 core

#define PI 3.1415926538
#define INV_PI (1.0 / 3.1415926538)
#define INV_2PI (0.5 / 3.1415926538)

layout(std140) uniform Camera
{
    mat4 U;         // P × V
    mat4 V;         // V
    mat3 F;         // F[0 ..< 3]
    vec3 position;  // F[3]
} camera;

layout(std140) uniform Atmosphere 
{
    float   radius_bottom;              
    float   radius_top;
    float   radius_sun; // angular radius
    
    float   mu_s_min;
    
    vec3    rayleigh_scattering;
    
    vec3    mie_scattering;
    float   mie_g;
    
    vec2    resolution_transmittance;
    float   resolution_scattering4_R;
    float   resolution_scattering4_M;
    float   resolution_scattering4_MS;
    float   resolution_scattering4_N;
    vec2    resolution_irradiance;
    
    vec3    irradiance; // solar irradiance
} atmosphere;

uniform vec3 origin;
uniform float scale;

uniform samplerCube globetex;

uniform sampler2D transmittance_table;
uniform sampler3D scattering_table;
uniform sampler2D irradiance_table;

out vec4 color;


const float pi = 3.1415926538;



// https://ebruneton.github.io/precomputed_atmospheric_scattering/atmosphere/functions.glsl
// phase functions 
float R_phi(const float nu) 
{
    return 3.0 / (16.0 * pi) * (1.0 + nu * nu);
}
float M_phi(const float nu, const float g) 
{
    // let k:F = (3 * (1 - g * g) as F) / ((2 + g * g) * (8 * .pi) as F)
    // this version seems to have better precision for some reason
    float k = 3.0 / (8.0 * pi) * (1.0 - g * g) / (2.0 + g * g);
    return k * (1.0 + nu * nu) / pow(1.0 + g * g - 2.0 * g * nu, 1.5);
}

float Texture_coordinate(const float parameter, const float resolution)
{
    return (0.5 / resolution) + parameter * (1.0 - 1.0 / resolution);
}

float Distance_to_atmosphere_top(const float r, const float mu) 
{
    float d = r * r * (mu * mu - 1.0) + atmosphere.radius_top * atmosphere.radius_top;
    return max(0.0, -r * mu + sqrt(max(0.0, d)));
}

bool Intersects_ground(const float r, const float mu) 
{
    float d = r * r * (mu * mu - 1.0) + atmosphere.radius_bottom * atmosphere.radius_bottom;
    return mu < 0 && d >= 0;
}

vec2 Transmittance_texture_coordinate(const float r, const float mu)
{
    float rho   = sqrt(max(0.0, r * r - atmosphere.radius_bottom * atmosphere.radius_bottom));
    float H     = sqrt( atmosphere.radius_top    * atmosphere.radius_top - 
                        atmosphere.radius_bottom * atmosphere.radius_bottom);
    
    float d     = Distance_to_atmosphere_top(r, mu);
    float d_min = atmosphere.radius_top - r; 
    float d_max = H + rho;
    
    float x_r   = rho / H; 
    float x_mu  = (d - d_min) / (d_max - d_min);
    
    float u     = Texture_coordinate(x_mu, atmosphere.resolution_transmittance.x); 
    float v     = Texture_coordinate(x_r,  atmosphere.resolution_transmittance.y);
    return vec2(u, v);
}

vec4 Scattering_texture_coordinate(
    const float r, const float mu, const float mu_s, const float nu,
    const bool intersects_ground) 
{
    float H     = sqrt( atmosphere.radius_top    * atmosphere.radius_top - 
                    atmosphere.radius_bottom * atmosphere.radius_bottom);
    float rho   = sqrt(max(0.0, r * r - atmosphere.radius_bottom * atmosphere.radius_bottom));
    float u_r   = Texture_coordinate(rho / H, atmosphere.resolution_scattering4_R);

    float r_mu  = r * mu;
    float discriminant = r_mu * r_mu - r * r + atmosphere.radius_bottom * atmosphere.radius_bottom;
    float u_mu;
    if (intersects_ground) 
    {
        float d     = -r_mu - sqrt(max(0.0, discriminant));
        float d_min = r - atmosphere.radius_bottom;
        float d_max = rho;
        float x     = d_max == d_min ? 0.0 : (d - d_min) / (d_max - d_min);
        u_mu        = 0.5 - 0.5 * Texture_coordinate(x, 0.5 * atmosphere.resolution_scattering4_M);
    } 
    else 
    {
        float d     = -r_mu + sqrt(max(0.0, discriminant + H * H));
        float d_min = atmosphere.radius_top - r;
        float d_max = rho + H;
        float x     = (d - d_min) / (d_max - d_min);
        u_mu        = 0.5 + 0.5 * Texture_coordinate(x, 0.5 * atmosphere.resolution_scattering4_M);
    }

    float d         = Distance_to_atmosphere_top(atmosphere.radius_bottom, mu_s);
    float d_min     = atmosphere.radius_top - atmosphere.radius_bottom;
    float d_max     = H;
    float a         = (d - d_min) / (d_max - d_min);
    float A         = -2.0 * atmosphere.mu_s_min * atmosphere.radius_bottom / (d_max - d_min);
    float u_mu_s    = Texture_coordinate(max(1.0 - a / A, 0.0) / (1.0 + a), 
                                        atmosphere.resolution_scattering4_MS);

    float u_nu      = (nu + 1.0) / 2.0;
    return vec4(u_nu, u_mu_s, u_mu, u_r);
}

vec2 Irradiance_texture_coordinate(const float r, const float mu_s)
{
    float x_r       = (r - atmosphere.radius_bottom) / (atmosphere.radius_top - atmosphere.radius_bottom);
    float x_mu_s    = (mu_s * 0.5 + 0.5);
    
    float u         = Texture_coordinate(x_mu_s, atmosphere.resolution_irradiance.x); 
    float v         = Texture_coordinate(x_r,    atmosphere.resolution_irradiance.y);
    return vec2(u, v);
}

vec3 Transmittance_top(const sampler2D transmittance_table, 
    const float r, const float mu) 
{
    vec2 t = Transmittance_texture_coordinate(r, mu);
    return texture(transmittance_table, t).rgb;
}
vec3 Transmittance_sun(const sampler2D transmittance_table, 
    const float r, const float mu_s) 
{
    float alpha = atmosphere.radius_sun;
    float sin   = atmosphere.radius_bottom / r;
    float cos   = -sqrt(max(0.0, 1.0 - sin * sin));
    return Transmittance_top(transmittance_table, r, mu_s) * smoothstep(-sin * alpha, sin * alpha, mu_s - cos);
}

vec3 Transmittance(const sampler2D transmittance_table, 
    const float r, const float mu, const float d, const bool intersects_ground) 
{
    float q     = d * d + 2.0 * r * mu * d + r * r;
    float r_d   = clamp(sqrt(q), atmosphere.radius_bottom, atmosphere.radius_top);
    float mu_d  = clamp((r * mu + d) / r_d, -1.0, 1.0);
    if (intersects_ground) 
    {
        vec3 transmittance =    Transmittance_top(transmittance_table, r_d, -mu_d) / 
                                Transmittance_top(transmittance_table, r, -mu);
        return min(transmittance, vec3(1.0));
    }
    else 
    {
        vec3 transmittance =    Transmittance_top(transmittance_table, r, mu) / 
                                Transmittance_top(transmittance_table, r_d, mu_d);
        return min(transmittance, vec3(1.0));
    }
}

vec3 Extrapolate_single_mie(const vec4 scattering) 
{
    if (scattering.r == 0.0)
    {
        return vec3(0.0);
    }
    else 
    {
        float scale =   (scattering.a * atmosphere.rayleigh_scattering.r) / 
                        (scattering.r * atmosphere.mie_scattering.r);
        vec3 ratio  = atmosphere.mie_scattering / atmosphere.rayleigh_scattering;
        return scattering.rgb * ratio * scale;
    }
}

void Scattering_combined(const sampler3D scattering_table, 
    const float r, const float mu, const float mu_s, const float nu,
    const bool intersects_ground, 
    out vec3 scattering_multiple, out vec3 scattering_single_mie)
{
    vec4 t  = Scattering_texture_coordinate(r, mu, mu_s, nu, intersects_ground);
    float x = t.x * (atmosphere.resolution_scattering4_N - 1.0); 
    float i = floor(x);
    vec3 t3[2] = vec3[2]
    (
        vec3((i       + t.y) / atmosphere.resolution_scattering4_N, t.z, t.w), 
        vec3((i + 1.0 + t.y) / atmosphere.resolution_scattering4_N, t.z, t.w)
    );
    float u = x - i;
    
    vec4 combined = texture(scattering_table, t3[0]) * (1.0 - u) + 
                    texture(scattering_table, t3[1]) *        u;
    scattering_multiple    = combined.rgb;
    scattering_single_mie  = Extrapolate_single_mie(combined);
}

vec3 Irradiance(const sampler2D irradiance_table, const float r, const float mu_s) 
{
    vec2 t = Irradiance_texture_coordinate(r, mu_s);
    return texture(irradiance_table, t).rgb;
}


void Radiance_sky(const sampler2D transmittance_table, const sampler3D scattering_table,
    vec3 camera, const vec3 ray, const float shadow_length, const vec3 sun_direction, 
    out vec3 transmittance, out vec3 radiance) 
{
    float r     = length(camera);
    float r_mu  = dot(camera, ray);
    float distance_to_atmosphere_top = -r_mu -
        sqrt(r_mu * r_mu - r * r + atmosphere.radius_top * atmosphere.radius_top);
    
    if (distance_to_atmosphere_top > 0.0) 
    {
        // viewer is in space
        camera += ray * distance_to_atmosphere_top;
        r       = atmosphere.radius_top;
        r_mu   += distance_to_atmosphere_top;
    } 
    else if (r > atmosphere.radius_top) 
    {
        // view ray does not intersect the atmosphere
        transmittance   = vec3(1.0);
        radiance        = vec3(0.0);
        return;
    }
    
    float mu    = r_mu / r;
    float mu_s  = dot(camera, sun_direction) / r;
    float nu    = dot(ray, sun_direction);
    bool intersects_ground = Intersects_ground(r, mu);
    
    if (intersects_ground) 
    {
        transmittance   = vec3(0.0);
    }
    else 
    {
        transmittance   = Transmittance_top(transmittance_table, r, mu);
    }
    
    vec3 scattering_multiple;
    vec3 scattering_single_mie;
    if (shadow_length == 0.0) 
    {
        Scattering_combined(scattering_table, r, mu, mu_s, nu, intersects_ground,
            scattering_multiple, scattering_single_mie);
    } 
    else 
    {
        float d         = shadow_length;
        float r_p       = clamp(sqrt(d * d + 2.0 * r * mu * d + r * r), 
            atmosphere.radius_bottom, atmosphere.radius_top);
        float mu_p      = (r * mu + d) / r_p;
        float mu_s_p    = (r * mu_s + d * nu) / r_p;

        Scattering_combined(scattering_table, r_p, mu_p, mu_s_p, nu, intersects_ground,
            scattering_multiple, scattering_single_mie);
        vec3 shadow = Transmittance(transmittance_table, r, mu, shadow_length, intersects_ground);
        scattering_multiple    *= shadow;
        scattering_single_mie  *= shadow;
    }
    
    radiance = scattering_multiple * R_phi(nu) + scattering_single_mie * M_phi(nu, atmosphere.mie_g);
}

void Radiance_sky_to_point(const sampler2D transmittance_table, const sampler3D scattering_table,
    vec3 camera, const vec3 point, const float shadow_length, const vec3 sun_direction, 
    out vec3 transmittance, out vec3 radiance) 
{
    vec3 ray    = normalize(point - camera);
    float r     = length(camera);
    float r_mu  = dot(camera, ray);
    float distance_to_atmosphere_top = -r_mu -
        sqrt(r_mu * r_mu - r * r + atmosphere.radius_top * atmosphere.radius_top);
    
    if (distance_to_atmosphere_top > 0.0) 
    {
        // viewer is in space
        camera += ray * distance_to_atmosphere_top;
        r       = atmosphere.radius_top;
        r_mu   += distance_to_atmosphere_top;
    }

    float mu    = r_mu / r;
    float mu_s  = dot(camera, sun_direction) / r;
    float nu    = dot(ray, sun_direction);
    float d     = length(point - camera);
    bool intersects_ground = Intersects_ground(r, mu);

    transmittance = Transmittance(transmittance_table, r, mu, d, intersects_ground);

    vec3 scattering_multiple; 
    vec3 scattering_single_mie;
    Scattering_combined(scattering_table, r, mu, mu_s, nu, intersects_ground,
        scattering_multiple, scattering_single_mie);
    
    d               = max(0.0, d - shadow_length);
    float r_p       = clamp(sqrt(d * d + 2.0 * r * mu * d + r * r), 
        atmosphere.radius_bottom, atmosphere.radius_top);
    float mu_p      = (r * mu + d) / r_p;
    float mu_s_p    = (r * mu_s + d * nu) / r_p;

    vec3 scattering_multiple_p;
    vec3 scattering_single_mie_p;
    Scattering_combined(scattering_table, r_p, mu_p, mu_s_p, nu, intersects_ground,
      scattering_multiple_p, scattering_single_mie_p);

    // combine the lookup results to get the scattering between camera and point.
    vec3 shadow_transmittance;
    if (shadow_length > 0.0) 
    {
        shadow_transmittance = Transmittance(transmittance_table, r, mu, d, intersects_ground);
    }
    else 
    {
        shadow_transmittance = transmittance;
    }
    
    scattering_multiple    -= shadow_transmittance * scattering_multiple_p;
    scattering_single_mie  -= shadow_transmittance * scattering_single_mie_p;
    scattering_single_mie   = Extrapolate_single_mie(vec4(scattering_multiple, scattering_single_mie.r));

    // hack to avoid rendering artifacts when the sun is below the horizon.
    scattering_single_mie  *= smoothstep(0.0, 0.01, mu_s);

    radiance = scattering_multiple * R_phi(nu) + scattering_single_mie * M_phi(nu, atmosphere.mie_g);
}

void Irradiance_sun_and_sky(const sampler2D transmittance_table, const sampler2D irradiance_table, 
    const vec3 point, const vec3 normal, const vec3 sun_direction, 
    out vec3 irradiance_sun, out vec3 irradiance_sky)
{
    float r     = length(point);
    float mu_s  = dot(point, sun_direction) / r;

    // indirect irradiance
    irradiance_sky = Irradiance(irradiance_table, r, mu_s) * (1.0 + dot(normal, point) / r) * 0.5;
    // direct irradiance
    irradiance_sun = atmosphere.irradiance * Transmittance_sun(transmittance_table, r, mu_s) *
        max(0.0, dot(normal, sun_direction));
}

// eburneton reference has code that can be used to model solar eclipses, but 
// just return 1.0 for now 
float Visibility_sun(const vec3 point, const vec3 sun_direction) 
{
    return 1.0;
}
float Visibility_sky(const vec3 point) 
{
    return 1.0;
}

vec4 Shade_atmosphere(
    const samplerCube albedo,
    const sampler2D transmittance_table, 
    const sampler3D scattering_table, 
    const sampler2D irradiance_table, 
    const vec3 camera, const vec3 ray, const vec3 sun_direction, const vec3 planet_center) 
{
    vec3  c             = planet_center - camera;
    float l             = dot(c, ray);
    float discriminant  = atmosphere.radius_bottom * atmosphere.radius_bottom + l * l - dot(c, c);
    
    //vec3 _ground;
    // radiance reflected by ground
    vec4 radiance_ground;
    if (discriminant < 0.0) 
    {
        radiance_ground = vec4(0.0);
        
        //_ground = vec3(0.0);
    }
    else 
    {
        // ray intersects ground 
        vec3 point  = camera + ray * (l - sqrt(discriminant));
        vec3 normal = normalize(point - planet_center);
        
        vec3 irradiance_sun, irradiance_sky;
        Irradiance_sun_and_sky(transmittance_table, irradiance_table, 
            point - planet_center, normal, sun_direction, 
            irradiance_sun, irradiance_sky);
        radiance_ground.rgb = texture(albedo, normal).rgb / pi * (
            irradiance_sun * Visibility_sun(point, sun_direction) + 
            irradiance_sky * Visibility_sky(point));
        
        vec3 transmittance, in_scatter;
        Radiance_sky_to_point(transmittance_table, scattering_table, 
            camera - planet_center, point - planet_center, 0.0, sun_direction, 
            transmittance, in_scatter);
        radiance_ground.rgb *= transmittance;
        radiance_ground.rgb += in_scatter;
        radiance_ground.a    = 1.0;
        
        //_ground = mix(vec3(0.3, 0.4, 0.2), vec3(0, 0.2, 0.33), texture(albedo, normal).r);
    }
    
    // radiance of sky 
    vec3 transmittance, radiance;
    Radiance_sky(transmittance_table, scattering_table, 
        camera - planet_center, ray, 0.0, sun_direction, 
        transmittance, radiance);
    
    if (dot(ray, sun_direction) > cos(atmosphere.radius_sun)) 
    {
        vec3 radiance_sun = atmosphere.irradiance / (pi * atmosphere.radius_sun * atmosphere.radius_sun);
        radiance += transmittance * radiance_sun;
    }
    
    radiance = mix(radiance, radiance_ground.rgb, radiance_ground.a);
    //return vec4(mix(_ground, pow(vec3(1.0) - exp(-radiance * 20), vec3(1.0 / 1.8)), 0.1), 1.0);
    return vec4(pow(vec3(1.0) - exp(-radiance * 20), vec3(1.0 / 1.8)), 1.0);
}


vec4 Pixel(const vec2 fragment) 
{
    float k  = atmosphere.radius_bottom / scale;
    vec3 ray = normalize(camera.F * vec3(fragment, 1));
    return Shade_atmosphere(globetex, transmittance_table, scattering_table, irradiance_table, 
        camera.position * k, ray, normalize(vec3(1, 1, 0.5)), origin * k);
}
void main()
{
    // vec2 fragments[5];
    // fragments[0] = vec2(-0.25, -0.25);
    // fragments[1] = vec2( 0.25, -0.25);
    // fragments[2] = vec2(-0.25,  0.25);
    // fragments[3] = vec2( 0.25,  0.25);
    // fragments[4] = vec2( 0,     0);
    // 
    // color = vec4(0, 0, 0, 0);
    // for (uint i = 0u; i < 5u; ++i) 
    // {
    //     color += Pixel(gl_FragCoord.xy + fragments[i]);
    // }
    // if (color.a > 0) 
    // {
    //     color.rgb = color.rgb / color.a;
    //     color.a  /= 5;
    // }
    color = Pixel(gl_FragCoord.xy);
}
