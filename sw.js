self.addEventListener('notificationclick', event => {
  event.notification.close();
  const destination = new URL('./#track', self.location.href).href;
  event.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(clients => {
    const existing = clients.find(client => client.url.startsWith(self.registration.scope));
    if (existing) return existing.focus();
    return self.clients.openWindow(destination);
  }));
});
