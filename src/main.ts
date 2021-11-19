// Inspiration: https://threejsfundamentals.org/threejs/lessons/threejs-shadertoy.html
import * as Three from 'three';
import { Vector4 } from 'three';
import shaderCode from './shader.glsl';
import skysphereAsset from './resources/skysphere.jpg';

const main = () => {
  const canvas = document.querySelector<HTMLCanvasElement>('#c');
  if (canvas == null) {
    return;
  }
  const renderer = new Three.WebGLRenderer({ canvas: canvas });
  renderer.autoClear = false;

  const camera = new Three.OrthographicCamera(-1, 1, 1, -1, -1, 1);
  const scene = new Three.Scene();
  const plane = new Three.PlaneBufferGeometry(2, 2);
  const loader = new Three.TextureLoader();
  const texture = loader.load(skysphereAsset);
  texture.minFilter = Three.NearestFilter;
  texture.magFilter = Three.NearestFilter;
  texture.wrapS = Three.RepeatWrapping;
  texture.wrapT = Three.RepeatWrapping;
  const uniforms: Record<
    string,
    Three.IUniform<number | Three.Vector3 | Three.Vector4 | Three.Texture>
  > = {
    iTime: { value: 0 },
    iResolution: { value: new Three.Vector3() },
    iMouse: { value: new Three.Vector4() },
    iChannel0: { value: texture },
  };
  const material = new Three.ShaderMaterial({
    fragmentShader: shaderCode,
    uniforms: uniforms,
  });
  scene.add(new Three.Mesh(plane, material));

  canvas.addEventListener('mousemove', (e) => {
    uniforms.iMouse.value = getMousePosition(e, canvas);
  });

  const render = (time: number) => {
    resizeRendererToDisplaySize(renderer);

    const canvas = renderer.domElement;
    Vector3OrNull(uniforms.iResolution.value)?.set(canvas.width, canvas.height, 1);
    uniforms.iTime.value = time * 0.001; // Time is in milliseconds

    renderer.render(scene, camera);

    requestAnimationFrame(render);
  };

  requestAnimationFrame(render);
};

const Vector3OrNull = (param: unknown): Three.Vector3 | null =>
  param instanceof Three.Vector3 ? param : null;

const resizeRendererToDisplaySize = (renderer: Three.WebGLRenderer): boolean => {
  const canvas = renderer.domElement;
  const width = canvas.clientWidth;
  const height = canvas.clientHeight;
  const needResize = canvas.width !== width || canvas.height !== height;
  if (needResize) {
    renderer.setSize(width, height, false);
  }
  return needResize;
};

const getMousePosition = (event: MouseEvent, element: Element): Three.Vector4 => {
  return new Vector4(
    event.clientX - element.getBoundingClientRect().left,
    element.getBoundingClientRect().bottom - event.clientY,
    0,
    0
  );
};

main();
