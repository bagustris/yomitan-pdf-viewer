if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("../service-worker.js").catch((error) => {
      console.error("Unable to register the offline viewer:", error);
    });
  });
}
