// Tự động gỡ bỏ (unregister) toàn bộ Service Worker để ngăn chặn lỗi cache PWA
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(function(registrations) {
    for(let registration of registrations) {
      registration.unregister();
      console.log('Service Worker đã được gỡ bỏ thành công để tránh lỗi cache.');
    }
  }).catch(function(err) {
    console.error('Lỗi khi gỡ bỏ Service Worker:', err);
  });
}
