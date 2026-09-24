let io;

const registerBedSocket = socketIo => { io = socketIo; };
const broadcastBedStatus = bed => {
  if (io && bed) io.emit('bed:status-changed', { bed });
};

module.exports = { registerBedSocket, broadcastBedStatus };