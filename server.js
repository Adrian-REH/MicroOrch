const path = require('path');
const fastify = require('fastify')({ logger: true });
const fastifyStatic = require('@fastify/static');
const args = process.argv.slice(2);

// Lista blanca de IPs
const allowedIps = new Set([args[0]]);
args.forEach(ip => {
  allowedIps.add(ip); // Agregar IP adicional desde parámetro
})

  fastify.addHook('onRequest', (request, reply, done) => {
  const clientIp = request.ip || request.socket.remoteAddress;
  if (!allowedIps.has(clientIp)) {
    reply.code(403).send('403 Forbidden: Access denied.');
  } else {
    done();
  }
});

// Servir archivos estáticos de la carpeta 'public'
fastify.register(fastifyStatic, {
  root: path.join(__dirname),
  prefix: '/', // la ruta raíz para acceder a los archivos
  // Opcional: habilitar listado de archivos
  // list: true
});

// Iniciar servidor
fastify.listen({ port: 8000, host: '0.0.0.0' }, (err, address) => {
  if (err) {
    fastify.log.error(err);
    process.exit(1);
  }
  fastify.log.info(`Server listening at ${address}`);
});

