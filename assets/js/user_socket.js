import { Socket } from "phoenix";

const system_user = (sender) => sender === "algora";

const init = () => {
  let socket = new Socket("/socket", { params: { token: window.userToken } });

  socket.connect();

  let channel;
  let chatBox;
  let chatInput;
  let chatMessages;
  let handleSend;

  const leave = (channel) => {
    channel.leave();
    if (chatInput) {
      chatInput.value = "";
      chatInput.removeEventListener("keypress", handleSend);
    }
    chatBox.classList.add("lg:w-0");
    chatBox.classList.remove("lg:w-[20rem]");
  };

  const join = ({ id, type }) => {
    if (channel) {
      leave(channel);
    }

    if (type !== "livestream") {
      return;
    }

    player = player;
    channel = socket.channel(`room:${id}`, {});
    chatBox = document.querySelector("#chat-box");
    chatInput = document.querySelector("#chat-input");
    chatMessages = document.querySelector("#chat-messages");
    chatMessages.scrollTop = chatMessages.scrollHeight;
    chatBox.classList.add("lg:w-[20rem]");
    chatBox.classList.remove("lg:w-0");

    handleSend = (event) => {
      if (event.key === "Enter" && chatInput.value.trim()) {
        channel.push("new_msg", { body: chatInput.value });
        chatInput.value = "";
      }
    };

    if (chatInput) {
      chatInput.addEventListener("keypress", handleSend);
    }

    channel.on("new_msg", (payload) => {
      const messageItem = document.createElement("div");

      const senderItem = document.createElement("span");
      senderItem.innerText = `${payload.user.handle}: `;
      senderItem.className = `font-semibold ${
        system_user(payload.user.handle)
          ? "text-emerald-400"
          : "text-indigo-400"
      }`;

      const bodyItem = document.createElement("span");
      bodyItem.innerText = `${payload.body}`;
      bodyItem.className = "font-medium text-gray-100";

      messageItem.appendChild(senderItem);
      messageItem.appendChild(bodyItem);

      chatMessages.appendChild(messageItem);
      chatMessages.scrollTop = chatMessages.scrollHeight;
    });

    channel
      .join()
      .receive("ok", (resp) => {
        console.log("Joined successfully", resp);
        window.channel = channel;
      })
      .receive("error", (resp) => {
        console.log("Unable to join", resp);
      });
  };

  return { join };
};

const Chat = init();

export default Chat;
