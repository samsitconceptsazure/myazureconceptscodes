const messages = document.getElementById('messages');
const input = document.getElementById('question');
const send = document.getElementById('send');
const history = [];
function bubble(text, role) {
  const el = document.createElement('div');
  el.className = `bubble ${role === 'user' ? 'user' : 'ai'}`;
  el.textContent = text; // no untrusted HTML injection
  messages.appendChild(el);
  messages.scrollTop = messages.scrollHeight;
  return el;
}
async function ask(question) {
  if (!question.trim() || send.disabled) return;
  send.disabled = true;
  bubble(question, 'user');
  const pending = bubble('Thinking…', 'assistant');
  try {
    const response = await fetch(window.CHAT_API_URL, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({message: question, history: history.slice(-10)})
    });
    const data = await response.json();
    if (!response.ok) throw Error(data.error || `HTTP ${response.status}`);
    pending.textContent = data.answer;
    history.push({role:'user',text:question},{role:'assistant',text:data.answer});
  } catch (err) { pending.textContent = `Sorry, the assistant is unavailable: ${err.message}`; }
  finally { send.disabled = false; input.focus(); }
}
document.getElementById('form').addEventListener('submit', e => {
  e.preventDefault(); const q = input.value; input.value = ''; ask(q);
});
document.querySelectorAll('[data-q]').forEach(b => b.addEventListener('click', () => ask(b.dataset.q)));
