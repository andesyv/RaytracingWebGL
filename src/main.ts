import * as Three from 'three';

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
  const material = new Three.MeshBasicMaterial({
    color: 'red',
  });
  scene.add(new Three.Mesh(plane, material));

  const render = () => {
    resizeRendererToDisplaySize(renderer);

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

main();
