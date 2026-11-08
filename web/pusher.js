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
      return response.json();
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
      return clientId();
    },

    clientId: clientId,

    hello: function (options) {
      options = options || {};
      var fields = deviceFields(options);
      if (!fields.token) {
        delete fields.token;
      }
      return post(statsBaseUrl, '/' + projectId + '/hi', fields);
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
      var fields = deviceFields({});
      delete fields.token;
      fields.status = status;
      return post(statsBaseUrl, '/' + projectId + '/n/' + nid, fields);
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
