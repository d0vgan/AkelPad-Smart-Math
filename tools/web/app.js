import createSmartMath from './smartmath.js';

const consoleBox = document.getElementById('console');
const output = document.getElementById('output');
const input = document.getElementById('input');
const statusLine = document.getElementById('status');

const history = [];
let historyPos = 0;
let module = null;
let calc = null;

function appendLine(text, className) {
  const div = document.createElement('div');
  div.className = 'line ' + className;
  div.textContent = text;
  output.appendChild(div);
  return div;
}

function scrollToEnd() {
  consoleBox.scrollTop = consoleBox.scrollHeight;
}

async function startCalculator() {
  module = await createSmartMath();
  calc = new module.WebCalc();
}

async function evaluateLine(line) {
  appendLine(line, 'in');
  let out;
  try {
    out = calc.evaluate(line);
  } catch (e) {
    // The WebAssembly instance cannot be used after an abort (for example, a stack overflow).
    appendLine('internal error: ' + e + ' (variables were reset)', 'err');
    await startCalculator();
    return;
  }
  if (out.status === module.LineStatus.Result) {
    appendLine(out.text, 'out').title = 'Click to copy';
  } else if (out.status === module.LineStatus.Error) {
    appendLine(out.text, 'err');
  }
}

async function evaluateLines(lines) {
  input.disabled = true;
  for (const line of lines) {
    await evaluateLine(line);
  }
  input.disabled = false;
  input.focus();
  scrollToEnd();
}

function remember(line) {
  if (line.trim() !== '' && history[history.length - 1] !== line) {
    history.push(line);
  }
  historyPos = history.length;
}

input.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    const line = input.value;
    input.value = '';
    remember(line);
    evaluateLines([line]);
  } else if (e.key === 'ArrowUp' && historyPos > 0) {
    e.preventDefault();
    input.value = history[--historyPos];
  } else if (e.key === 'ArrowDown' && historyPos < history.length) {
    e.preventDefault();
    historyPos++;
    input.value = historyPos < history.length ? history[historyPos] : '';
  } else if (e.key === 'Escape') {
    input.value = '';
    historyPos = history.length;
  }
});

input.addEventListener('paste', (e) => {
  const text = e.clipboardData.getData('text');
  if (!/[\r\n]/.test(text)) {
    return;
  }
  e.preventDefault();
  const lines = (input.value + text).split(/\r\n|\r|\n/);
  if (lines[lines.length - 1] === '') {
    lines.pop();
  }
  input.value = '';
  lines.forEach(remember);
  evaluateLines(lines);
});

output.addEventListener('click', async (e) => {
  const target = e.target;
  if (!target.classList.contains('out') || !navigator.clipboard) {
    return;
  }
  await navigator.clipboard.writeText(target.textContent);
  target.classList.add('copied');
  target.title = 'Copied';
  setTimeout(() => {
    target.classList.remove('copied');
    target.title = 'Click to copy';
  }, 800);
});

consoleBox.addEventListener('click', () => {
  if (window.getSelection().isCollapsed) {
    input.focus();
  }
});

document.getElementById('clear').addEventListener('click', () => {
  output.replaceChildren();
  input.focus();
});

document.getElementById('reset').addEventListener('click', () => {
  if (!calc) {
    return;
  }
  calc.reset();
  appendLine('Variables, user functions, and ans were reset.', 'muted');
  scrollToEnd();
  input.focus();
});

const views = document.querySelector('.views');
const helpHost = document.getElementById('helpHost');
const helpBtn = document.getElementById('helpBtn');
const splitter = document.getElementById('splitter');

const kDefaultHelpRatio = 0.7;
const kMinPanePx = 180;
let helpRatio = kDefaultHelpRatio;
let helpOpen = false;

function clampHelpRatio(ratio, totalWidth) {
  const minRatio = kMinPanePx / totalWidth;
  const maxRatio = 1 - minRatio;
  if (!(minRatio < maxRatio)) {
    return kDefaultHelpRatio;
  }
  return Math.min(maxRatio, Math.max(minRatio, ratio));
}

function applySplit() {
  views.classList.toggle('help-open', helpOpen);
  helpBtn.setAttribute('aria-pressed', String(helpOpen));
  splitter.hidden = !helpOpen;
  if (!helpOpen) {
    helpHost.style.flex = '0 0 0';
    return;
  }
  helpRatio = clampHelpRatio(helpRatio, views.clientWidth);
  helpHost.style.flex = '0 0 ' + (helpRatio * 100) + '%';
}

async function ensureHelpLoaded() {
  if (helpHost.childElementCount !== 0) {
    return;
  }
  const response = await fetch('help.html');
  if (!response.ok) {
    throw new Error('HTTP ' + response.status);
  }
  const doc = new DOMParser().parseFromString(await response.text(), 'text/html');
  const page = doc.querySelector('.help-page');
  if (page === null) {
    throw new Error('help.html has no .help-page');
  }
  helpHost.append(...page.children);
}

async function setHelpOpen(open) {
  if (open) {
    await ensureHelpLoaded();
  }
  helpOpen = open;
  applySplit();
  if (!open) {
    input.focus();
  }
}

helpBtn.addEventListener('click', async () => {
  try {
    await setHelpOpen(!helpOpen);
  } catch (e) {
    helpHost.replaceChildren();
    const p = document.createElement('p');
    p.className = 'web-note';
    p.textContent = 'Could not load Help: ' + e;
    helpHost.append(p);
    helpOpen = true;
    applySplit();
  }
});

let dragging = false;

splitter.addEventListener('pointerdown', (e) => {
  if (e.button !== 0) {
    return;
  }
  dragging = true;
  splitter.setPointerCapture(e.pointerId);
  document.body.classList.add('is-resizing');
});

splitter.addEventListener('pointermove', (e) => {
  if (!dragging) {
    return;
  }
  const rect = views.getBoundingClientRect();
  helpRatio = clampHelpRatio((rect.right - e.clientX) / rect.width, rect.width);
  applySplit();
});

function endDrag() {
  if (!dragging) {
    return;
  }
  dragging = false;
  document.body.classList.remove('is-resizing');
}

splitter.addEventListener('pointerup', endDrag);
splitter.addEventListener('pointercancel', endDrag);

splitter.addEventListener('keydown', (e) => {
  const step = e.shiftKey ? 0.1 : 0.03;
  if (e.key === 'ArrowLeft') {
    helpRatio = clampHelpRatio(helpRatio + step, views.clientWidth);
  } else if (e.key === 'ArrowRight') {
    helpRatio = clampHelpRatio(helpRatio - step, views.clientWidth);
  } else {
    return;
  }
  e.preventDefault();
  applySplit();
});

window.addEventListener('resize', () => {
  if (helpOpen) {
    applySplit();
  }
});

try {
  await startCalculator();
  statusLine.textContent = 'Time values, complex numbers, and lambdas are on.';
  appendLine('Type a math expression and press Enter. Pasted lines are evaluated one by one.', 'muted');
  input.disabled = false;
  input.focus();
} catch (e) {
  statusLine.textContent = 'Could not load the calculator: ' + e;
  statusLine.className = 'line err';
}
