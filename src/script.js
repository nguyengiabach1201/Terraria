const canvas = document.getElementById("game");
const ctx = canvas.getContext("2d");

function setCanvasSize() {
  const dpr = window.devicePixelRatio || 2;

  const width = 256, height = 256;
  console.log(width, height);

  if (canvas.width !== width * dpr || canvas.height !== height * dpr) {
    canvas.width = width * dpr;
    canvas.height = height * dpr;
  }

  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.scale(dpr, dpr);
}
setCanvasSize();