import { type Channel, Socket } from "phoenix";

const systemUser = (sender) => sender === "algora";

const init = () => {
  let socket = new Socket("/socket", { params: { token: window.userToken } });
  socket.connect();

  // const main = document.querySelector("body");
  // const sidePanel = document.querySelector("#side-panel");

  // if (!main) {
  //   throw new Error("Could not initialize chat");
  // }

  let channel: Channel;
  let chatInput;
  let chatMessages;
  let handleSend;

  const leave = (channel: Channel) => {
    channel.leave();
    if (chatInput) {
      chatInput.value = "";
      chatInput.removeEventListener("keypress", handleSend);
    }
    // sidePanel.classList.add("lg:w-0");
    // sidePanel.classList.remove("lg:w-[24rem]");
    // sidePanel.classList.remove("lg:flex");
    // main.classList.remove("lg:mr-[24rem]");
  };

  const join = ({ id }) => {
    if (channel) {
      leave(channel);
    }

    channel = socket.channel(`room:${id}`, {});
    chatInput = document.querySelector("#chat-input");
    chatMessages = document.querySelector("#chat-messages");
    chatMessages.scrollTop = chatMessages.scrollHeight;
    // sidePanel.classList.add("lg:w-[24rem]");
    // sidePanel.classList.add("lg:flex");
    // sidePanel.classList.remove("lg:w-0");
    // main.classList.add("lg:mr-[24rem]");

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
        systemUser(payload.user.handle) ? "text-emerald-400" : "text-indigo-400"
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
