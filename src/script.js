const canvas = document.getElementById("game");
const ctx = canvas.getContext("2d");

function setCanvasSize() {
  const pixelRatio = (function() {
    const ctx = document.createElement("canvas").getContext("2d"),
      dpr = window.devicePixelRatio || 1,
      bsr = ctx.webkitBackingStorePixelRatio ||
        ctx.mozBackingStorePixelRatio ||
        ctx.msBackingStorePixelRatio ||
        ctx.oBackingStorePixelRatio ||
        ctx.backingStorePixelRatio || 1;

    return dpr / bsr;
  })();

  const createHiDPICanvas = function(w, h, ratio) {
    if (!ratio) { ratio = pixelRatio; }
    canvas.width = w * ratio;
    canvas.height = h * ratio;
    canvas.style.width = w + "px";
    canvas.style.height = h + "px";
    canvas.getContext("2d").setTransform(ratio, 0, 0, ratio, 0, 0);
    canvas.id = "lumina-canvas";
  }

  createHiDPICanvas(256, 256, 4);
}
setCanvasSize();