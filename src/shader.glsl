// By Anders Syvertsen
#include <common>


struct Sphere {
    vec3 p;
    float r;
    vec3 color;
    float reflectance;
};

uniform vec3 iResolution;
uniform vec4 iMouse;
uniform float iTime;
// #iChannel0 'file://skysphere.jpg'
uniform sampler2D iChannel0;

// Game Physics Cookbook, Gabor Szauer, 2017, 10.1
float raySphere(vec3 rOrigin, vec3 rDir, Sphere s) {
    // Ray origin to sphere center
    vec3 e = s.p - rOrigin;
    float rSq = s.r * s.r;
    float eSq = dot(e, e);
    // Project e onto ray dir
    float a = dot(e, rDir);
    float bSq = eSq - (a * a);
    float f = sqrt(rSq - bSq);

    // No collision has happened, return negative number
    if (rSq - (eSq - (a * a)) < 0.0)
        return -1.0;
    // Ray starts inside the sphere
    else if (eSq < rSq)
        return a + f; // Just reverse direction
    // else Normal intersection
    return a - f;
}

const int RAYCASTBOUNCES = 3;
const int SPHERECOUNT = 3;
#define ANTIALIASING 1

// out vec4 fragColor = gl_FragColor, in vec2 fragCoord = gl_FragCoord.xy
void main()
{
    gl_FragColor = vec4(0., 0., 0., 1.0);
#if ANTIALIASING
    for (int AAI = 0; AAI < 9; ++AAI) {
        vec2 AAOffset = vec2(float(AAI / 3 - 1), float(AAI % 3 - 1)) * (0.5 / iResolution.xy);
        // Normalized pixel coordinates (from 0 to 1)
        vec2 uv = gl_FragCoord.xy/iResolution.xy + AAOffset;
#else
        vec2 uv = gl_FragCoord.xy/iResolution.xy;
#endif
        // Normalized mouse coordinates
        vec2 mCoords = (iMouse.xy / iResolution.xy) * 2.0 - 1.0;
        // x,y,z = sin(angleX),sin(angleY),cos(angleX) * cos(angleY)
        vec3 unitSphere = vec3(sin(-mCoords.x * PI), sin(-mCoords.y * PI), cos(-mCoords.x * PI) * cos(-mCoords.y * PI));
        vec3 lightPos = vec3(mCoords, 0.5);

        vec3 rayOrigin = vec3(uv * 2.0 - 1.0, 0.0);
        vec3 rayDir = normalize(vec3((uv * 2.0 - 1.0) * 0.1, 1.0));

        Sphere spheres[SPHERECOUNT] = Sphere[SPHERECOUNT](
            Sphere(vec3(sin(iTime) * 0.7 - 0.4 + 0.4, -0.5, 0.5), 0.3, vec3(1.0, 1.0, 1.0), 1.0),
            Sphere(vec3(-0.4, 0.2, 0.5), 0.3, vec3(1.0, 1.0, 1.0), 1.0),
            Sphere(vec3(0.4, -0.5, 0.3), 0.2, vec3(0.0, 0.0, 1.0), 0.0)
        );

        // vec3 lightDir = -unitSphere;

        vec3 finalColor = vec3(1.0);
        // Start at negative depth, meaning behind the camera.
        float depth = -1.0;
        int closestSphere = -1;
        bool bDidBounce = false;
        float reflectance = 1.0;
        // Loop per bounce
        for (int bounce = 0; bounce < RAYCASTBOUNCES; bounce++) {
            depth = -1.0;
            // Send a ray through each sphere and check which one is the closest one.
            for (int i = 0; i < SPHERECOUNT; ++i) {
                float newDepth = raySphere(rayOrigin + EPSILON * rayDir, rayDir, spheres[i]);
                // Find the closest intersection point that is not behind ray
                if (0.0 < newDepth && (newDepth < depth || depth < 0.0)) {
                    closestSphere = i;
                    depth = newDepth;
                }
            }
            // If we hit something (if depth is between 0.0 and 1.0)
            if (0.0 < depth) {
                vec3 surfacePoint = rayOrigin + depth * rayDir;
                vec3 lightDir = normalize(surfacePoint - lightPos);
                // vec3 normal = gradientNormal(rayOrigin, rayDir, spherePos, sphereRadius);
                vec3 normal = normalize(surfacePoint - spheres[closestSphere].p);

                // Shadow feelers
                bool bShadow = false;
                for (int j = 0; j < SPHERECOUNT; ++j) {
                    // Skip self check
                    if (closestSphere == j) continue;

                    // Check if anything intersects between surface and light
                    if (0.0 < raySphere(surfacePoint - 0.01 * lightDir, -lightDir, spheres[j])) {
                        bShadow = true;
                        break;
                    }
                }

                // If shadow feelers hit something, add some shadow
                if (bShadow && 0.0 < reflectance)
                    finalColor = vec3(0.0);
                // Else, unobstructed path to light, add some color
                else {
                    // vec3 phong = texture(iChannel0, texCoords).rgb * spheres[closestSphere].color * (max(dot(lightDir, normal), 0.0) + 0.15)
                    Sphere s = spheres[closestSphere];
                    // vec3 phong = s.color * max(dot(lightDir, normal), 0.1);
                    // Color is additively added with each bounce adding 0.5 times less
                    // finalColor += s.color * pow(0.75, float(bounce+1));
                    finalColor *= s.color;
                    reflectance *= s.reflectance;
                }

                // Set new ray origin to the surface hit.
                rayOrigin = surfacePoint;
                rayDir = reflect(rayDir, normal);
                bDidBounce = true;
            }
        }

        vec2 sphereCoords = rayDir.xy * 0.5 + 0.5;
        if (-1 < closestSphere) {
            finalColor *= mix(vec3(1.0), texture(iChannel0, sphereCoords).rgb, reflectance);
            finalColor *= mix(1.0, (1.0 / pow(distance(rayOrigin.xy, lightPos.xy), 0.6)), reflectance);
        } else {
            finalColor = texture(iChannel0, sphereCoords).rgb * (1.0 / pow(distance(rayOrigin.xy, lightPos.xy), 0.6));
        }

        // Output to screen
        gl_FragColor.xyz += finalColor;
#if ANTIALIASING
    }
    gl_FragColor.xyz /= 9.0;
#endif
}