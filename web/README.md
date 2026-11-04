# pusher web

Script client for `stats.pusher.tr`. The page passes `projectId` and `statsKey`.
Firebase web cannot subscribe to a topic itself, so `subscribe` sends the FCM
token and topic to stats. Stats checks the token with Firebase and does not
store a rejected token.

`projectId` identifies the project. It is not a secret. `statsKey` signs each
request. It is visible in the page, the same way the mobile SDK carries it.
Do not put a Firebase service account or server key in the page.

## Install

Ship `dist/pusher.js` as `https://cdn.pusher.tr/js/pusher.js`. Rebuild it with `npm run uglify` after changing `pusher.js`, then put that file at `domain/services/cdn/js/pusher.js`. Deploy copies it into place.

```html
<script src="https://cdn.pusher.tr/js/pusher.js"></script>
<script>
  Pusher.init({
    projectId: 'YOUR_PROJECT_ID',
    statsKey: 'YOUR_STATS_KEY',
  });
</script>
```

## Methods

| Method | Role |
| --- | --- |
| `init({ projectId, statsKey, baseUrl })` | Saves the keys. Returns the client id. |
| `subscribe({ token, topic })` | Asks stats to subscribe this FCM token. |
| `unsubscribe({ token, topic })` | Asks stats to unsubscribe it. |
| `hello({ token })` | Device hello. A token is stored only if Firebase accepts it. |
| `receipt({ nid, status })` | `status` is `1` delivered or `2` opened. |
| `clientId()` | Stable id kept in `localStorage`. |

`token` comes from Firebase `getToken`. `topic` must be a topic key that
exists on the project.

```html
<script>
  Pusher.subscribe({ token: fcmToken, topic: 'news' });
</script>
```

Signing matches the mobile SDK: HMAC-SHA256 over `METHOD`, path without
`/v1`, unix seconds, and the raw body. Headers are `x-timestamp` and
`x-signature`.
