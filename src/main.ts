// Inspiration: https://threejsfundamentals.org/threejs/lessons/threejs-shadertoy.html
import * as Three from 'three';
import { Vector4 } from 'three';
import shaderCode from './shader.glsl';

const uniforms: { [uniform: string]: { value: any } } = {
  iTime: { value: 0 },
  iResolution: { value: new Three.Vector3() },
  iMouse: { value: new Three.Vector4() },
};

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
    uniforms.iResolution.value.set(canvas.width, canvas.height, 1);
    uniforms.iTime.value = time * 0.001; // Time is in milliseconds

    renderer.render(scene, camera);

    requestAnimationFrame(render);
  };

  requestAnimationFrame(render);
};

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
    event.clientY - element.getBoundingClientRect().top,
    0,
    0
  );
};

main();
