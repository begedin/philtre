import '../css/app.css';

// direct link to the raw scss, so any change will immediately be live-reloaded
import '../../src/css/philtre.scss';

import 'phoenix_html';
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';

// import hooks also directly from source, for live-reload
import { Code, ContentEditable, History, Selection } from '../../src/hooks';

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');
const liveSocket = new LiveSocket('/live', Socket, {
  hooks: { Code, ContentEditable, Selection, History },
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();

Object.defineProperty(window, 'liveSocket', {
  value: liveSocket,
  writable: false,
});
