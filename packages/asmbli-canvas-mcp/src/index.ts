#!/usr/bin/env node

import { CanvasServer } from './server.js';

const server = new CanvasServer();
server.run().catch(console.error);