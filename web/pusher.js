/* Pusher web client. Topic subscribe goes through stats.pusher.tr. */
(function (root) {
  'use strict';

  var statsBaseUrl = 'https://stats.pusher.tr';
  var sendBaseUrl = 'https://send.pusher.tr';
  var projectId = '';
  var statsKey = '';
  var sdkVersion = '0.0.2';

  function trim(value) {
    return value == null ? '' : String(value).trim();
  }

  function requireInit() {
    if (!projectId || !statsKey) {
      throw new Error('Call Pusher.init first');
    }
  }

  function clientId() {
    var key = 'pusher.clientId';
    var id = '';
    try {
      id = localStorage.getItem(key) || '';
    } catch (error) {
      id = '';
    }
    if (!id) {
      id = (root.crypto && crypto.randomUUID)
        ? crypto.randomUUID()
        : String(Date.now()) + Math.random().toString(16).slice(2);
      try {
        localStorage.setItem(key, id);
      } catch (error) {
        /* private mode */
      }
    }
    return id;
  }

  function bytesToBase64(bytes) {
    var text = '';
    for (var i = 0; i < bytes.length; i++) {
      text += String.fromCharCode(bytes[i]);
    }
    return btoa(text);
  }

  function sign(method, path, body) {
    var unix = Math.floor(Date.now() / 1000);
    var canonical = [method, path, String(unix), body].join('\n');
    var encoder = new TextEncoder();
    return crypto.subtle
      .importKey(
        'raw',
        encoder.encode(statsKey),
        { name: 'HMAC', hash: 'SHA-256' },
        false,
        ['sign']
      )
      .then(function (key) {
        return crypto.subtle.sign('HMAC', key, encoder.encode(canonical));
      })
      .then(function (mac) {
        return {
          timestamp: String(unix),
          signature: bytesToBase64(new Uint8Array(mac)),
        };
      });
  }

  var retryDelaysSeconds = [30, 120, 600, 1800, 3600];
  var maxPending = 200;
  var pendingMaxAgeMs = 48 * 60 * 60 * 1000;
  var pendingStorageKey = 'pusher.pending_queue';
  var memoryPending = [];
  var retryAttempt = 0;
  var retryTimer = null;

  function readPending() {
    var now = Date.now();
    var list = memoryPending;
    try {
      if (typeof localStorage !== 'undefined') {
        var raw = localStorage.getItem(pendingStorageKey);
        if (raw) {
          var parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            list = parsed;
          }
        }
      }
    } catch (error) {
      /* ServiceWorker or private mode */
    }
    return list.filter(function (item) {
      return item && typeof item.at === 'number' && now - item.at < pendingMaxAgeMs;
    });
  }

  function writePending(list) {
    memoryPending = list;
    try {
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem(pendingStorageKey, JSON.stringify(list));
      }
    } catch (error) {
      /* ServiceWorker or private mode */
    }
  }

  function samePending(a, b) {
    if (!a || !b || a.kind !== b.kind) return false;
    return a.kind === 'hello' || (a.nid === b.nid && a.status === b.status);
  }

  function enqueuePending(item) {
    var existing = readPending();
    var match = null;
    for (var i = 0; i < existing.length; i++) {
      if (samePending(existing[i], item)) {
        match = existing[i];
        break;
      }
    }
    var merged = {
      kind: item.kind,
      nid: item.nid,
      status: item.status,
      token: item.token,
      at: match ? match.at : item.at || Date.now(),
    };
    var next = existing.filter(function (it) {
      return !samePending(it, item);
    });
    next.push(merged);
    if (next.length > maxPending) {
      next = next.slice(next.length - maxPending);
    }
    writePending(next);
  }

  function removePending(item) {
    var next = readPending().filter(function (it) {
      return !samePending(it, item);
    });
    writePending(next);
  }

  function scheduleRetry() {
    if (retryTimer !== null) return;
    var idx = Math.min(retryAttempt, retryDelaysSeconds.length - 1);
    var delayMs = retryDelaysSeconds[idx] * 1000;
    retryAttempt += 1;
    retryTimer = setTimeout(function () {
      retryTimer = null;
      flushPending();
    }, delayMs);
  }

  function sendPendingItem(item) {
    var fields = deviceFields({ token: item.token });
    var path;
    if (item.kind === 'hello') {
      if (!fields.token) delete fields.token;
      path = '/' + projectId + '/hi';
    } else {
      delete fields.token;
      fields.status = item.status;
      path = '/' + projectId + '/n/' + item.nid;
    }
    return post(statsBaseUrl, path, fields).then(
      function (res) {
        removePending(item);
        retryAttempt = 0;
        return res;
      },
      function (err) {
        var code = err && err.status ? err.status : 0;
        var retryable = !code || code === 408 || code === 429 || code >= 500;
        if (!retryable) {
          removePending(item);
          throw err;
        }
        enqueuePending(item);
        scheduleRetry();
        throw err;
      }
    );
  }

  function flushPending() {
    if (!projectId || !statsKey) return Promise.resolve();
    var items = readPending();
    writePending(items);
    var chain = Promise.resolve();
    items.forEach(function (item) {
      chain = chain.then(function () {
        return sendPendingItem(item);
      });
    });
    return chain.catch(function () {});
  }

  function post(baseUrl, path, payload) {
    requireInit();
    var body = JSON.stringify(payload);
    return sign('POST', path, body).then(function (signed) {
      return fetch(baseUrl + '/v1' + path, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-timestamp': signed.timestamp,
          'x-signature': signed.signature,
        },
        body: body,
      });
    }).then(function (response) {
      return response.json().catch(function () {
        return {};
      }).then(function (json) {
        if (!response.ok) {
          var err = new Error((json && json.message) || ('HTTP ' + response.status));
          err.status = response.status;
          throw err;
        }
        return json;
      });
    });
  }

  function get(baseUrl, pathAndQuery) {
    requireInit();
    return sign('GET', pathAndQuery, '').then(function (signed) {
      return fetch(baseUrl + '/v1' + pathAndQuery, {
        method: 'GET',
        headers: {
          'x-timestamp': signed.timestamp,
          'x-signature': signed.signature,
        },
      });
    }).then(function (response) {
      return response.json();
    });
  }

  function deviceFields(extra) {
    var nav = root.navigator || {};
    return {
      clientId: clientId(),
      platform: 'web',
      locale: nav.language || '',
      isEmulator: false,
      debugMode: false,
      appVersionCode: '0',
      sdkVersion: sdkVersion,
      osVersion: nav.platform || '',
      appVersion: '0',
      brand: 'web',
      model: nav.userAgent ? String(nav.userAgent).slice(0, 120) : 'web',
      token: extra && extra.token ? trim(extra.token) : undefined,
    };
  }

  var Pusher = {
    init: function (options) {
      options = options || {};
      projectId = trim(options.projectId);
      statsKey = trim(options.statsKey);
      if (options.baseUrl) {
        statsBaseUrl = trim(options.baseUrl).replace(/\/+$/, '');
      }
      if (options.sendBaseUrl) {
        sendBaseUrl = trim(options.sendBaseUrl).replace(/\/+$/, '');
      }
      if (!projectId || !statsKey) {
        throw new Error('projectId and statsKey required');
      }
      flushPending();
      return clientId();
    },

    clientId: clientId,

    hello: function (options) {
      options = options || {};
      var item = {
        kind: 'hello',
        token: options.token ? trim(options.token) : undefined,
        at: Date.now(),
      };
      enqueuePending(item);
      return sendPendingItem(item).then(function (res) {
        flushPending();
        return res;
      });
    },

    receipt: function (options) {
      options = options || {};
      var nid = trim(options.nid);
      var status = options.status;
      if (!nid || !/^[A-Za-z0-9_-]{1,128}$/.test(nid)) {
        return Promise.reject(new Error('nid required'));
      }
      if (status !== 1 && status !== 2) {
        return Promise.reject(new Error('status must be 1 or 2'));
      }
      var item = {
        kind: 'receipt',
        nid: nid,
        status: status,
        at: Date.now(),
      };
      enqueuePending(item);
      if (status === 1) {
        // Spread delivered receipts across 0–15s (within ServiceWorker 30s waitUntil window).
        var jitterMs = Math.floor(Math.random() * 15000);
        return new Promise(function (resolve) {
          setTimeout(resolve, jitterMs);
        }).then(function () {
          return sendPendingItem(item).then(function (res) {
            flushPending();
            return res;
          });
        });
      }
      return sendPendingItem(item).then(function (res) {
        flushPending();
        return res;
      });
    },

    inbox: function () {
      requireInit();
      var id = clientId();
      var path =
        '/' + projectId + '/notifications/inbox/' + encodeURIComponent(id);
      return get(sendBaseUrl, path).then(function (body) {
        if (!body || body.status !== true) {
          throw new Error((body && body.message) || 'inbox failed');
        }
        return Array.isArray(body.data) ? body.data : [];
      });
    },

    subscribe: function (options) {
      return topic(options, 'sub');
    },

    unsubscribe: function (options) {
      return topic(options, 'unsub');
    },
  };

  function topic(options, op) {
    options = options || {};
    var token = trim(options.token);
    var name = trim(options.topic);
    if (!token || !name) {
      return Promise.reject(new Error('token and topic required'));
    }
    return post(statsBaseUrl, '/' + projectId + '/topic', {
      token: token,
      topic: name,
      op: op,
    });
  }

  root.Pusher = Pusher;
})(typeof globalThis !== 'undefined' ? globalThis : window);
