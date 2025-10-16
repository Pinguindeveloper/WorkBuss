// Obter o nome real do recurso no ambiente NUI (FiveM expõe GetParentResourceName)
const resourceName = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName()
    : 'WorkBuss';

// Elementos DOM
const container = document.getElementById('busworkPanel');
const closeBtn = document.getElementById('closeBtn');
const cancelBtn = document.getElementById('cancelBtn');
const startBtn = document.getElementById('startBtn');
const stopBtn = document.getElementById('stopBtn');
const statusSection = document.getElementById('statusSection');
const progressBar = document.getElementById('progressBar');
const progressText = document.getElementById('progressText');

// Estado do trabalho
let isWorking = false;

// Removido: implementação customizada que quebrava o callback NUI

// Função para enviar mensagens para o Lua
function sendNUIMessage(action, data = {}) {
    fetch(`https://${resourceName}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => {
        console.log('Resposta do servidor:', resp);
    }).catch(err => {
        console.error('Erro ao enviar mensagem:', err);
    });
}

// Abrir painel
function openPanel(data) {
    container.classList.add('active');
    document.body.style.overflow = 'hidden';
    
    // Atualizar informações se fornecidas
    if (data) {
        if (data.salary) {
            document.getElementById('salaryRange').textContent = `R$ ${data.salary.min} - R$ ${data.salary.max}`;
        }
        if (data.totalStops) {
            document.getElementById('totalStops').textContent = `${data.totalStops} Pontos`;
        }
    }
}

// Fechar painel
function closePanel() {
    container.classList.remove('active');
    document.body.style.overflow = 'auto';
    sendNUIMessage('closeUI');
}

// Iniciar trabalho
function startWork() {
    isWorking = true;
    
    // Atualizar UI
    startBtn.style.display = 'none';
    cancelBtn.style.display = 'none';
    stopBtn.style.display = 'flex';
    statusSection.style.display = 'block';
    
    // Enviar mensagem para o Lua
    sendNUIMessage('startWork');
    
    // Fechar o painel após iniciar
    setTimeout(() => {
        closePanel();
    }, 500);
}

// Parar trabalho
function stopWork() {
    isWorking = false;
    
    // Atualizar UI
    startBtn.style.display = 'flex';
    cancelBtn.style.display = 'flex';
    stopBtn.style.display = 'none';
    statusSection.style.display = 'none';
    
    // Resetar progresso
    updateProgress(0, 22);
    
    // Enviar mensagem para o Lua
    sendNUIMessage('stopWork');
    
    // Fechar o painel
    closePanel();
}

// Atualizar progresso
function updateProgress(current, total) {
    const percentage = (current / total) * 100;
    progressBar.style.width = `${percentage}%`;
    progressText.textContent = `Parada ${current}/${total}`;
}

// Event Listeners
closeBtn.addEventListener('click', closePanel);
cancelBtn.addEventListener('click', closePanel);
startBtn.addEventListener('click', startWork);
stopBtn.addEventListener('click', stopWork);

// Fechar com ESC
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && container.classList.contains('active')) {
        closePanel();
    }
});

// Receber mensagens do Lua
window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch (data.action) {
        case 'openUI':
            openPanel(data);
            break;
            
        case 'closeUI':
            closePanel();
            break;
            
        case 'updateProgress':
            if (data.current !== undefined && data.total !== undefined) {
                updateProgress(data.current, data.total);
            }
            break;
            
        case 'workStarted':
            isWorking = true;
            startBtn.style.display = 'none';
            cancelBtn.style.display = 'none';
            stopBtn.style.display = 'flex';
            statusSection.style.display = 'block';
            break;
            
        case 'workStopped':
            isWorking = false;
            startBtn.style.display = 'flex';
            cancelBtn.style.display = 'flex';
            stopBtn.style.display = 'none';
            statusSection.style.display = 'none';
            updateProgress(0, 22);
            break;
    }
});

// Log para debug
console.log('BusWork UI carregada com sucesso!');
console.log('Nome do recurso:', resourceName);

