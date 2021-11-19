// By Anders Syvertsen
#include <common>

#define SPHERECOUNT 5
#define MAX_BOUNCES 3
#define ANTIALIASING

const vec3 lightPos = vec3(10.0, 8.0, 3.0);
const float tanCoefficients = 0.5 * (PI / 180.0);

uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iTime;
uniform sampler2D iChannel0;

// --- Manually calculate a projection matrix --------------------------
mat4 perspective(float n, float f, float aspect, float FOV) {
    float S = 1.0 / tan(FOV * tanCoefficients);

    return mat4(
        S, 0, 0, 0,
        0, S * aspect, 0, 0,
        0, 0, -f/(f-n), -1.0,
        0, 0, (-2.0 * f * n) / (f-n), 0
    );
}

// ---- Quaternions for simplified rotations -----------------------------
vec4 makeQuat(float rad, vec3 axis) {
    return vec4(sin(rad * 0.5) * axis, cos(rad * 0.5));
}

vec4 mulQuat(vec4 q1, vec4 q2) {
    return vec4(
        cross(q1.xyz, q2.xyz) + q1.w * q2.xyz + q2.w * q1.xyz,
        q1.w * q2.w - dot(q1.xyz, q2.xyz)
    );
}

mat3 quatToRot(vec4 q) {
    return mat3(
        1.0 - 2.0*q.y*q.y - 2.0*q.z*q.z,2.0*q.x*q.y - 2.0*q.z*q.w,      2.0*q.x*q.z + 2.0*q.y*q.w,
        2.0*q.x*q.y + 2.0*q.z*q.w,      1.0 - 2.0*q.x*q.x - 2.0*q.z*q.z,2.0*q.y*q.z - 2.0*q.x*q.w,
        2.0*q.x*q.z - 2.0*q.y*q.w,      2.0*q.y*q.z + 2.0*q.x*q.w,      1.0 - 2.0*q.x*q.x - 2.0*q.y*q.y
    );
}

mat4 translate(mat4 mat, vec3 pos) {
    mat4 t = mat4(1.0);
    t[3].xyz = pos;
    return t * mat;
}

// ---- Intersection tests --------------------------------------------------
// https://www.iquilezles.org/www/articles/intersectors/intersectors.htm

vec2 raySphere(in vec3 ro, in vec3 rd, in vec3 ce, in float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

// plane degined by p (p.xyz must be normalized)
float rayPlane( in vec3 ro, in vec3 rd, in vec4 p )
{
    return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

vec2 sphericalCoords(vec3 c) {
    // https://mathworld.wolfram.com/SphericalCoordinates.html
    float phi = 0.5 * atan(c.x / c.z) / PI;
    return vec2(c.z < 0.0 ? phi : phi - 0.5, acos(-c.y) / PI);
}

float rand2(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}


void mainImage(out vec4 fragColor, in vec2 texCoords) {
    fragColor = vec4(0., 0., 0., 1.0);
    #ifdef ANTIALIASING
    for (int AAI = 0; AAI < 9; ++AAI) {
        vec2 AAOffset = vec2(float(AAI / 3 - 1), float(AAI % 3 - 1)) * (0.5 / iResolution.xy);
        // ----- Shadertoy stuff --------------------------------------------
        vec2 uv = 2.0 * texCoords / iResolution.xy - 1.0 + AAOffset;
        #else
        vec2 uv = 2.0 * texCoords / iResolution.xy - 1.0;
        #endif
        vec2 mPos = 2.0 * iMouse.xy / iResolution.xy - 1.0;

        mat4 pMat = perspective(0.1, 100.0, iResolution.x / iResolution.y, 90.0);
        mat4 vMat = translate(mat4(quatToRot(
            mulQuat(
                makeQuat(-mPos.x * PI, vec3(0., 1.0, 0.)),
                makeQuat(mPos.y * PI, vec3(1., 0.0, 0.))
            )
        )), vec3(0., 0., -30.0));
        mat4 pInv = inverse(pMat);
        mat4 vInv = inverse(vMat);
        mat4 MVP = inverse(pMat * vMat);
        
        // ------- Normal raytracing stuff ------------------------------------
        vec4 near = MVP * vec4(uv, -1.0, 1.0);
        near /= near.w;
        vec4 far = MVP * vec4(uv, 1.0, 1.0);
        far /= far.w;

        vec3 rayOrigin = near.xyz;
        vec3 rayDirection = normalize((far - near).xyz);

        // ----- Scene setup ---------------------------------------
        vec4 scene[SPHERECOUNT] = vec4[SPHERECOUNT](
            vec4(4.0 * sin(iTime), 2.0 * cos(iTime), -7.0, 1.3),
            vec4(3.0 * cos(iTime), 2.0, -6.0 * sin(iTime), 1.3),
            vec4(0.0, 2.0 * sin(iTime + 1.4) + 2.0, -8.0, 2.3),
            vec4(10.0 * cos(0.2 * iTime + 0.4), 0.2 * sin(iTime), 14.0 * sin(0.1 * iTime + 1.4) - 4.0, 5.0),
            vec4(3.0 * cos(iTime) * sin(iTime) + 7.0, 5.0 * sin(iTime * 1.3 - 1.2) + 2.0, -5.0, 0.9 * cos(iTime) + 2.4)
        );
        vec4 plane = vec4(normalize(vec3(0.1 * sin(iTime * 0.1), -1.0, 0.1 * cos(iTime * 0.1))), -10.0);
        int objectType = 0;
        float transmittance = 1.0;

        // ------- Main logic -------------------------------------------
        for (int i = 0; i < MAX_BOUNCES; ++i) {
            float dist = 100000.0;
            int closest = 0;
            for (int j = 0; j < SPHERECOUNT; j++) {
                vec2 hit = raySphere(rayOrigin, rayDirection, scene[j].xyz, scene[j].w);
                if (0.0 < hit.x && hit.x < dist) {
                    closest = j;
                    dist = hit.x;
                    objectType = 0;
                }
            }
            // We only have one plane, so we either hit it or not
            float hit = rayPlane(rayOrigin, rayDirection, plane);
            if (0.0 < hit && hit < dist) {
                objectType = 1;
                dist = hit;
            }
            if (0.0 < dist && dist < 10000.0) {
                vec3 hitPos = rayOrigin + rayDirection * dist;
                vec3 normal = objectType == 1 ? plane.xyz : normalize(scene[closest].xyz - hitPos);
                vec3 lightDir = normalize(hitPos - lightPos);

                // ------- Shadow feelers -------------------------------------------
                // plane cannot cast shadows, so don't need to trace it
                int occlusion = 0;
                vec3 rotAxis = normalize(cross(-lightDir, vec3(0., 1.0, 0.)));
                for (int j = 0; j < 9; ++j) {
                    vec2 r = 0.02 * vec2(rand2(uv + vec2(j * 2, -j * 3) * 0.1), rand2(uv + vec2(3, float(j)*1.2) * 0.1)) - 0.01;
                    mat3 rot = quatToRot(mulQuat(makeQuat(r.x, rotAxis), makeQuat(r.y, cross(rotAxis, -lightDir))));
                    vec3 offsetDir = rot * -lightDir;
                    for (int k = 0; k < SPHERECOUNT; ++k) {
                        if (closest != k && 0.0 < raySphere(hitPos - 0.01 * lightDir, offsetDir, scene[k].xyz, scene[k].w).x) {
                            occlusion++;
                            break;
                        }
                    }
                }
                
                transmittance *= float(9 - occlusion) / 9.0;

                // ------- Color blending -------------------------------------------
                vec3 phong = vec3(normal * 0.5 + 0.5) * max(0.04, dot(lightDir, normal));
                fragColor.rgb += phong * pow(0.5, float(i)) * transmittance;

                rayDirection = reflect(rayDirection, normal);
                rayOrigin = hitPos + 0.001 * rayDirection;
            } else {
                fragColor.rgb += texture(iChannel0, sphericalCoords(rayDirection.xyz)).rgb * pow(0.5, float(i)) * transmittance;
                break;
            }
        }
        
    #ifdef ANTIALIASING
    }
    fragColor.xyz /= 9.0;
    #endif
}

void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}