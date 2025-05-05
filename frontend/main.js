const serverUrl = 'http://localhost:3000';

const nameField = document.querySelector('#name-field');
const submitButton = document.querySelector('#submit-button');
const messageArea = document.querySelector('#message-area');

submitButton.addEventListener('click', sendRequest)

async function sendRequest() {
  const name = nameField.value;

  const response = await fetch(serverUrl + '/add-name', {
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    method: 'post',
    body: JSON.stringify({ name: name })
  });  

  const json = await response.json();

  const message = json.message || json.error;
  messageArea.innerText = message;
  messageArea.style.color = response.ok ? 'green' : 'red';

}
