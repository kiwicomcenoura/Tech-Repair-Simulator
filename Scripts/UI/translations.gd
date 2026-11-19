extends RefCounted

# Source Portuguese, English, and Spanish, separated by vertical bars.
const ROWS := """Configurações|Settings|Configuración
Idioma e moeda|Language and currency|Idioma y moneda
Volume dos efeitos|Effects volume|Volumen de efectos
Resolução da janela|Window resolution|Resolución de la ventana
Modo de exibição|Display mode|Modo de pantalla
Janela|Windowed|Ventana
Tela cheia|Fullscreen|Pantalla completa
Janela sem borda|Borderless window|Ventana sin bordes
Resoluções maiores são ajustadas à área útil do monitor.|Larger resolutions are scaled to fit the available screen area.|Las resoluciones mayores se ajustan al área disponible de la pantalla.
Neste modo, o jogo usa a resolução do monitor.|This mode uses the monitor resolution.|Este modo usa la resolución del monitor.
Idioma|Language|Idioma
Moeda|Currency|Moneda
Voltar|Back|Volver
Salvar (F5)|Save (F5)|Guardar (F5)
Restaurar (F9)|Load (F9)|Cargar (F9)
Decorar (F2)|Decorate (F2)|Decorar (F2)
Sair do jogo|Quit game|Salir del juego
Voltar ao jogo|Resume game|Volver al juego
Sair do jogo?|Quit game?|¿Salir del juego?
Tem certeza de que deseja sair?|Are you sure you want to quit?|¿Seguro que quieres salir?
Cancelar|Cancel|Cancelar
Sair|Quit|Salir
Progresso salvo.|Progress saved.|Progreso guardado.
Não foi possível salvar.|Could not save.|No se pudo guardar.
Pedidos (O)|Orders (O)|Pedidos (O)
Configurações (Esc)|Settings (Esc)|Configuración (Esc)
FERRAMENTAS|TOOLS|HERRAMIENTAS
F — Atendimento e pedidos|F — Service counter and orders|F — Mostrador y pedidos
F — Atendimento e pedidos↵E — Pegar gabinete|F — Service counter and orders↵E — Pick up PC|F — Mostrador y pedidos↵E — Recoger PC
F — Abrir caixa de ferramentas|F — Open toolbox|F — Abrir caja de herramientas
F — Abrir armário para guardar peça|F — Open cabinet to store part|F — Abrir armario para guardar pieza
F — Abrir armário↵I — Inventário|F — Open cabinet↵I — Inventory|F — Abrir armario↵I — Inventario
F — Abrir bancada|F — Open workbench|F — Abrir banco
F — Abrir bancada↵E — Pegar gabinete|F — Open workbench↵E — Pick up PC|F — Abrir banco↵E — Recoger PC
F — Abrir bancada↵Desligue o PC para transportá-lo|F — Open workbench↵Turn off the PC before carrying it|F — Abrir banco↵Apaga el PC antes de transportarlo
Shift+E — Pegar gabinete|Shift+E — Pick up PC|Mayús+E — Recoger PC
F — Acessar computador|F — Access computer|F — Acceder al equipo
E — Colocar gabinete na bancada|E — Place PC on workbench|E — Colocar PC en el banco
E — Guardar componente na bandeja|E — Put component in tray|E — Colocar componente en la bandeja
Carregando: %s↵E — Soltar|Carrying: %s↵E — Drop|Transportando: %s↵E — Soltar
E — Abrir embalagem · |E — Open package · |E — Abrir paquete · 
E — Pegar · |E — Pick up · |E — Recoger · 
Atendimento · Ordens de serviço|Service counter · Work orders|Mostrador · Órdenes de servicio
Voltar · Esc|Back · Esc|Volver · Esc
Propostas|Offers|Ofertas
Fila|Queue|Cola
Histórico|History|Historial
Receber gabinete|Receive PC|Recibir PC
Recusar|Decline|Rechazar
Priorizar|Prioritize|Priorizar
Entregar ao cliente|Deliver to customer|Entregar al cliente
Entregue · Pagamento concluído|Delivered · Payment complete|Entregado · Pago completo
Receba e entregue no balcão (F). Consulte a fila com O. O adiantamento cobre as peças; a mão de obra é paga na entrega.|Receive and deliver at the counter (F). Open the queue with O. The deposit covers parts; labor is paid on delivery.|Recibe y entrega en el mostrador (F). Abre la cola con O. El anticipo cubre las piezas y la mano de obra se paga al entregar.
Nenhuma proposta agora. Novos clientes chegam enquanto você trabalha na oficina.|No offers right now. New customers arrive while you work.|Por ahora no hay ofertas. Llegan nuevos clientes mientras trabajas.
A fila está vazia. Receba um serviço no balcão para começar.|The queue is empty. Accept a job to get started.|La cola está vacía. Acepta un trabajo para comenzar.
Seus serviços concluídos aparecerão aqui.|Completed jobs will appear here.|Los trabajos terminados aparecerán aquí.
O gabinete será recebido fisicamente ao aceitar. Peças são compradas à parte no TechMarket.|Accept to receive the PC. Parts are purchased separately in TechMarket.|Acepta para recibir el PC. Las piezas se compran por separado en TechMarket.
%d / %d serviços ativos · %d entregas · %s|%d / %d active jobs · %d deliveries · %s|%d / %d trabajos activos · %d entregas · %s
Total: %s · Adiantamento para peças: %s · Na entrega: %s|Total: %s · Parts deposit: %s · Due on delivery: %s|Total: %s · Anticipo para piezas: %s · Al entregar: %s
%s recebido. Gabinete no balcão; adiantamento de %s para peças.|%s accepted. PC at the counter; %s parts deposit.|%s aceptado. PC en el mostrador; anticipo de %s para piezas.
%s entregue a %s! Recebidos %s restantes.|%s delivered to %s! Remaining payment of %s received.|¡%s entregado a %s! Se recibió el pago restante de %s.
Corrigir erros de memória|Fix memory errors|Corregir errores de memoria
Restabelecer a alimentação|Restore power|Restablecer la alimentación
Recuperar a saída de vídeo|Restore video output|Restaurar la salida de vídeo
Trocar a refrigeração defeituosa|Replace faulty cooling|Cambiar la refrigeración defectuosa
Ampliar a memória para 16 GB|Upgrade memory to 16 GB|Ampliar la memoria a 16 GB
Revisão e diagnóstico completo|Full inspection and diagnosis|Revisión y diagnóstico completo
Resolver falhas de vídeo e memória|Fix video and memory faults|Resolver fallos de vídeo y memoria
Segundo módulo de 8 GB DDR4|Second 8 GB DDR4 module|Segundo módulo DDR4 de 8 GB
Manter o módulo original no primeiro slot|Keep the original module in the first slot|Mantener el módulo original en la primera ranura
Inicialização aprovada após o serviço|Successful boot after service|Arranque correcto tras el servicio
Desligar e fechar o gabinete com os quatro parafusos|Turn off the PC and close the case with all four screws|Apagar el PC y cerrar la caja con los cuatro tornillos
Trazer o gabinete correto nas mãos ao balcão|Carry the correct PC to the counter|Llevar el PC correcto al mostrador
Todos os Componentes|All Components|Todos los componentes
CATEGORIAS|CATEGORIES|CATEGORÍAS
Processador|Processor|Procesador
Refrigeração|Cooling|Refrigeración
Placa-mãe|Motherboard|Placa base
Memória RAM|RAM|Memoria RAM
Placa de vídeo|Graphics card|Tarjeta gráfica
Armazenamento|Storage|Almacenamiento
Fonte|Power supply|Fuente de alimentación
Comprar|Buy|Comprar
Saldo disponível · %s|Available balance · %s|Saldo disponible · %s
%s↵%s↵%s↵↵Entrega embalada.↵Instalação manual.|%s↵%s↵%s↵↵Packaged delivery.↵Manual installation.|%s↵%s↵%s↵↵Entrega en caja.↵Instalación manual.
Você tem certeza que quer comprar esse item?↵↵%s↵Valor: %s · Entrega na oficina|Are you sure you want to buy this item?↵↵%s↵Price: %s · Workshop delivery|¿Seguro que quieres comprar este artículo?↵↵%s↵Precio: %s · Entrega en el taller
CONFIRMAR COMPRA / TECHMARKET|CONFIRM PURCHASE / TECHMARKET|CONFIRMAR COMPRA / TECHMARKET
Sim|Yes|Sí
Não|No|No
Dissipador|Heat spreader|Disipador
Sem dissipador|No heat spreader|Sin disipador
Preto|Black|Negro
Branco|White|Blanco
Azul|Blue|Azul
Vermelho|Red|Rojo
Dissipador opcional · 4 cores|Optional heat spreader · 4 colors|Disipador opcional · 4 colores
TechMarket / Componentes · Entrega física em 3 s|TechMarket / Components · Delivery in 3 s|TechMarket / Componentes · Entrega en 3 s
Passe o mouse sobre um produto para ver a imagem e sua categoria.|Hover over a product to see its image and category.|Pasa el ratón sobre un producto para ver su imagen y categoría.
Computador da oficina|Workshop computer|Equipo del taller
Computador desligado|Computer off|Equipo apagado
Ligar computador|Power on computer|Encender equipo
Desligar computador|Shut down computer|Apagar equipo
Desligar|Shut down|Apagar
Ligar PC|Power on PC|Encender PC
Desligar PC|Shut down PC|Apagar PC
Voltar à oficina|Return to workshop|Volver al taller
Voltar à inspeção|Back to inspection|Volver a la inspección
← Voltar à bancada|← Back to workbench|← Volver al banco
Acessar SO|Open OS|Abrir sistema
TechOS  /  OFICINA|TechOS  /  WORKSHOP|TechOS  /  TALLER
TechOS / CLIENTE|TechOS / CUSTOMER|TechOS / CLIENTE
Sessão do cliente|Customer session|Sesión del cliente
Jogador  /  Sessão local|Player  /  Local session|Jugador  /  Sesión local
▦  Iniciar|▦  Start|▦  Inicio
Dia %02d · local|Day %02d · local|Día %02d · local
Mensagens|Messages|Mensajes
Clientes|Customers|Clientes
Loja de Peças|Parts Store|Tienda de piezas
Finanças|Finances|Finanzas
Marketing|Marketing|Marketing
Arquivos|Files|Archivos
ESPAÇO LOCAL|LOCAL SPACE|ESPACIO LOCAL
TechOS↵Sessão local|TechOS↵Local session|TechOS↵Sesión local
Visão geral|Overview|Resumen
Aplicativo|Application|Aplicación
Fechar janela|Close window|Cerrar ventana
Minimizar janela|Minimize window|Minimizar ventana
Bancada de Manutenção|Repair Workbench|Banco de mantenimiento
OFICINA  /  ESTAÇÃO TÉCNICA|WORKSHOP  /  REPAIR STATION|TALLER  /  ESTACIÓN TÉCNICA
01  /  BANCADA DE MANUTENÇÃO|01  /  REPAIR WORKBENCH|01  /  BANCO DE MANTENIMIENTO
EQUIPAMENTO|EQUIPMENT|EQUIPO
○  SEM EQUIPAMENTO|○  NO EQUIPMENT|○  SIN EQUIPO
Condição|Condition|Estado
Tipo|Type|Tipo
Diagnóstico|Diagnostics|Diagnóstico
Componentes|Components|Componentes
Testes|Tests|Pruebas
Inspecionar|Inspect|Inspeccionar
Trocar componente|Replace component|Cambiar componente
Substituir peça|Replace part|Sustituir pieza
Finalizar manutenção|Finish repair|Terminar reparación
Ações de manutenção|Repair actions|Acciones de mantenimiento
Nenhum equipamento na bancada|No equipment on the workbench|No hay equipo en el banco
Nenhum equipamento↵na bancada|No equipment↵on the workbench|No hay equipo↵en el banco
Aguardando equipamento|Waiting for equipment|Esperando equipo
Nenhum diagnóstico disponível|No diagnostics available|No hay diagnóstico disponible
Iniciar diagnóstico|Start diagnostics|Iniciar diagnóstico
Iniciar POST|Run POST|Ejecutar POST
Testar RAM|Test RAM|Probar RAM
Testar vídeo|Test video|Probar vídeo
Testar componente|Test component|Probar componente
Testando…|Testing…|Probando…
Testes do equipamento|Equipment tests|Pruebas del equipo
Resultado do equipamento|Equipment results|Resultados del equipo
TEMPERATURA|TEMPERATURE|TEMPERATURA
FUNCIONAMENTO|OPERATION|FUNCIONAMIENTO
MONITOR DE TESTE|TEST MONITOR|MONITOR DE PRUEBA
Sem medição|No reading|Sin medición
Slot vazio|Empty slot|Ranura vacía
Desligado|Off|Apagado
Em teste|Testing|En prueba
Falhou|Failed|Falló
Inicialização|Startup|Inicio
Sem sinal|No signal|Sin señal
Aguardando sincronização|Waiting for sync|Esperando sincronización
Sinal ativo · Verifique o POST|Active signal · Check POST|Señal activa · Revisa el POST
Imagem estável|Stable picture|Imagen estable
Teste de vídeo em andamento|Video test in progress|Prueba de vídeo en curso
Anomalias · Sinal intermitente|Artifacts · Intermittent signal|Artefactos · Señal intermitente
ANOMALIAS|ARTIFACTS|ARTEFACTOS
Sistema do cliente|Customer system|Sistema del cliente
POST em execução|Running POST|POST en ejecución
Consulte o diagnóstico|Check diagnostics|Consulta el diagnóstico
TELA DO PC DO CLIENTE|CUSTOMER PC DISPLAY|PANTALLA DEL PC DEL CLIENTE
INSPEÇÃO VISUAL  /  DESKTOP ATX|VISUAL INSPECTION  /  ATX DESKTOP|INSPECCIÓN VISUAL  /  PC ATX
Gabinete — lateral esquerda|Case — left side|Caja — lado izquierdo
Gabinete — vista 3D|Case — 3D view|Caja — vista 3D
Vista 3D|3D View|Vista 3D
Em breve!|Coming soon!|¡Próximamente!
Vista 2D|2D View|Vista 2D
Clique para usar a ferramenta · Arraste para girar · Roda para zoom · Botão direito para restaurar.|Click to use the tool · Drag to rotate · Scroll to zoom · Right-click to reset.|Clic para usar la herramienta · Arrastra para girar · Rueda para zoom · Clic derecho para restablecer.
1 · Mãos: peças, conectores e travas↵2 · Phillips: parafusos↵Conectores soltos ficam fora do encaixe.|1 · Hands: parts, connectors and latches↵2 · Phillips: screws↵Unplugged connectors sit outside their sockets.|1 · Manos: piezas, conectores y pestañas↵2 · Phillips: tornillos↵Los conectores sueltos quedan fuera de su toma.
Mãos|Hands|Manos
FIXAÇÃO DA TAMPA|SIDE PANEL FASTENERS|FIJACIÓN DEL PANEL
Tampa instalada|Panel installed|Panel instalado
Tampa retirada|Panel removed|Panel retirado
Retirar tampa|Remove panel|Retirar panel
Recolocar tampa|Reattach panel|Colocar panel
PEÇAS · INVENTÁRIO / BANDEJA|PARTS · INVENTORY / TRAY|PIEZAS · INVENTARIO / BANDEJA
Selecione uma peça|Select a part|Selecciona una pieza
Traga uma peça desembalada|Bring an unpacked part|Trae una pieza desempaquetada
Armário de peças|Parts cabinet|Armario de piezas
Inventário da oficina|Workshop inventory|Inventario del taller
Todas as categorias|All categories|Todas las categorías
Guardar peça das mãos|Store held part|Guardar pieza en mano
Bloco de Notas|Notepad|Bloc de notas
Teste de Cores|Color Test|Prueba de colores
Instalar|Install|Instalar
Abrir|Open|Abrir
Início|Home|Inicio
Notícias|News|Noticias
Ajuda|Help|Ayuda
Documentos|Documents|Documentos
Downloads|Downloads|Descargas
Digite uma anotação para testar o teclado.|Type a note to test the keyboard.|Escribe una nota para probar el teclado.
Página inicial↵↵Escolha uma página nos favoritos ou digite inicio, noticias ou ajuda.|Home page↵↵Choose a bookmark or enter inicio, noticias, or ajuda.|Página inicial↵↵Elige un favorito o escribe inicio, noticias o ajuda.
Notícias locais↵↵A feira de tecnologia da cidade abre neste fim de semana.|Local news↵↵The city technology fair opens this weekend.|Noticias locales↵↵La feria tecnológica de la ciudad abre este fin de semana.
Central de ajuda↵↵Use o Explorer para ver arquivos e a Store para instalar aplicativos.|Help center↵↵Use Explorer to view files and Store to install apps.|Centro de ayuda↵↵Usa Explorer para ver archivos y Store para instalar aplicaciones.
Página indisponível. Abra um dos favoritos do Browser.|Page unavailable. Open a Browser bookmark.|Página no disponible. Abre un favorito del Browser.
Lembretes.txt|Reminders.txt|Recordatorios.txt
Leia-me.txt|Readme.txt|Léeme.txt
Selecione um arquivo em %s.|Select a file in %s.|Selecciona un archivo en %s.
Revisar os documentos da semana.↵Separar os recibos da próxima viagem.|Review this week's documents.↵Set aside the receipts for the next trip.|Revisar los documentos de la semana.↵Separar los recibos del próximo viaje.
Arquivos baixados nesta máquina aparecem aqui.|Files downloaded on this PC appear here.|Aquí aparecen los archivos descargados en este PC.
Receber serviço|Accept job|Aceptar trabajo
Recusar proposta|Decline offer|Rechazar oferta
Aproxime-se do balcão para receber o cliente.|Approach the counter to receive the customer.|Acércate al mostrador para atender al cliente.
Conclua um pedido para liberar espaço na fila.|Finish a job to free up space in the queue.|Termina un pedido para hacer espacio en la cola.
Conclua os itens da lista antes de entregar.|Complete the checklist before delivery.|Completa la lista antes de entregar.
Leve o gabinete até o balcão.|Bring the PC to the counter.|Lleva el PC al mostrador.
Substituir %s|Replace %s|Sustituir %s
Testar %s|Test %s|Probar %s
Verificar %s|Check %s|Verificar %s
a memória instalada|the installed RAM|la memoria instalada
Uso este computador para trabalhar em casa.|I use this computer to work from home.|Uso este equipo para trabajar desde casa.
É o computador dos meus estudos.|This is the computer I use for school.|Es el equipo que uso para estudiar.
Uso a máquina para editar meus projetos.|I use this machine to edit my projects.|Uso este equipo para editar mis proyectos.
É o computador da minha pequena loja.|This is the computer for my small shop.|Es el equipo de mi pequeña tienda.
Gosto de jogar nas horas vagas.|I like to play games in my spare time.|Me gusta jugar en mi tiempo libre.
Minha família usa este computador todos os dias.|My family uses this computer every day.|Mi familia usa este equipo todos los días.
O computador trava e mostra telas de erro quando abro vários programas.|The computer freezes and shows errors when I open several programs.|El equipo se congela y muestra errores cuando abro varios programas.
Meus aplicativos fecham sozinhos e às vezes o computador não inicia.|My apps close on their own and sometimes the computer won't boot.|Mis aplicaciones se cierran solas y a veces el equipo no arranca.
Começaram a aparecer erros de memória e reinicializações inesperadas.|I started getting memory errors and unexpected restarts.|Han aparecido errores de memoria y reinicios inesperados.
Aperto o botão e a máquina não dá sinal de vida.|I press the button and the machine shows no sign of life.|Pulso el botón y el equipo no da señales de vida.
Depois de uma queda de energia, o computador parou de ligar.|The computer stopped turning on after a power outage.|Después de un corte de luz, el equipo dejó de encender.
O computador desligou durante o uso e não ligou mais.|The computer shut down while I was using it and won't turn back on.|El equipo se apagó mientras lo usaba y no volvió a encender.
O monitor fica sem imagem, mesmo com o computador ligado.|The monitor stays blank even though the computer is on.|El monitor se queda sin imagen aunque el equipo esté encendido.
Aparecem blocos coloridos na tela e a imagem some por instantes.|Colored blocks appear on the screen and the picture briefly cuts out.|Aparecen bloques de colores y la imagen desaparece por instantes.
Já testei outro monitor, mas continuo sem vídeo.|I tried another monitor, but there's still no video.|Ya probé otro monitor, pero sigo sin imagen.
A ventoinha do processador parou de funcionar.|The CPU fan stopped spinning.|El ventilador del procesador dejó de funcionar.
O cooler faz muito barulho e a máquina desliga.|The cooler makes a lot of noise and the machine shuts down.|El disipador hace mucho ruido y el equipo se apaga.
A refrigeração começou a falhar; preciso voltar a usar o computador.|The cooling started failing and I need the computer working again.|La refrigeración empezó a fallar y necesito volver a usar el equipo.
Quero mais memória para abrir vários programas: instale um segundo módulo de 8 GB DDR4.|I want more memory for multiple programs. Install a second 8 GB DDR4 module.|Quiero más memoria para abrir varios programas. Instala un segundo módulo DDR4 de 8 GB.
Preciso de 16 GB de RAM no total, mantendo meu módulo atual de 8 GB.|I need 16 GB of RAM in total while keeping my current 8 GB module.|Necesito 16 GB de RAM en total y quiero mantener mi módulo actual de 8 GB.
Adicione mais 8 GB DDR4 no segundo slot para melhorar minha rotina.|Add another 8 GB of DDR4 in the second slot to speed up my workflow.|Añade otros 8 GB DDR4 en la segunda ranura para mejorar mi flujo de trabajo.
Comprei este computador usado. Quero conferir todos os componentes antes de usá-lo.|I bought this computer used and want every component checked before I use it.|Compré este equipo usado y quiero revisar todos los componentes antes de usarlo.
Vou passar o computador para outra pessoa e preciso de uma revisão completa.|I'm passing this computer on to someone else and need a full inspection.|Voy a pasar el equipo a otra persona y necesito una revisión completa.
A máquina está funcionando, mas quero uma verificação de todas as peças.|The machine works, but I want every part checked.|El equipo funciona, pero quiero que se revisen todas las piezas.
Além de não dar vídeo, a máquina já apresentava erros de memória.|There's no video, and the machine was already showing memory errors.|Además de no dar imagen, el equipo ya mostraba errores de memoria.
O computador perdeu a imagem; antes disso, também travava com erros de RAM.|The computer lost its picture. Before that it also froze with RAM errors.|El equipo perdió la imagen. Antes también se congelaba con errores de RAM.
Preciso corrigir dois problemas: falhas de vídeo e de memória.|I need two problems fixed: video and memory faults.|Necesito resolver dos problemas: fallos de vídeo y de memoria.
Personalizar oficina|Customize workshop|Personalizar taller
Escolha uma superfície. Veja a mudança na oficina.|Select a surface. Preview the change in the workshop.|Elige una superficie. Mira el cambio en el taller.
Paredes|Walls|Paredes
Chão|Floor|Suelo
Bancada de manutenção|Repair workbench|Banco de mantenimiento
Mesa do computador|Computer desk|Mesa del equipo
Balcão de atendimento|Service counter|Mostrador
Armário|Cabinet|Armario
COR DO ACABAMENTO|FINISH COLOR|COLOR DEL ACABADO
Escolher outra cor|Choose another color|Elegir otro color
Restaurar esta superfície|Reset this surface|Restaurar esta superficie
Aplicar e salvar|Apply and save|Aplicar y guardar
Cancelar · ESC|Cancel · Esc|Cancelar · Esc
Fechar · ESC|Close · Esc|Cerrar · Esc
Prévia · %s↵Aplicar salva; Cancelar mantém o visual anterior.|Preview · %s↵Apply saves; Cancel keeps the previous appearance.|Vista previa · %s↵Aplicar guarda; Cancelar mantiene el aspecto anterior.
INVENTÁRIO · %d / %d|INVENTORY · %d / %d|INVENTARIO · %d / %d
ARMÁRIO · %d / %d|CABINET · %d / %d|ARMARIO · %d / %d
Espaço %02d · Arraste uma peça aqui|Slot %02d · Drag a part here|Espacio %02d · Arrastra una pieza aquí
Selecione uma peça para transferir. Gabinetes são transportados nas mãos.|Select a part to transfer. Carry PCs by hand.|Selecciona una pieza para transferir. Los equipos se transportan a mano.
Aproxime-se do armário.|Move closer to the cabinet.|Acércate al armario.
Presente · não testado|Present · untested|Presente · sin probar
Vazio|Empty|Vacío
Perfeito estado|Excellent condition|Excelente estado
Bom|Good|Bueno
Mediano|Fair|Regular
Ruim|Poor|Malo
Quebrado|Broken|Averiado
Condição desconhecida|Unknown condition|Estado desconocido
Não avaliada|Not assessed|Sin evaluar
Em manutenção|Under repair|En reparación
Inicialização aprovada|Boot successful|Arranque correcto
Não testado|Untested|Sin probar
Executando POST…|Running POST…|Ejecutando POST…
POST concluído. Sistema inicializado; componentes essenciais reconhecidos.|POST complete. System started and essential components recognized.|POST completo. Sistema iniciado y componentes esenciales reconocidos.
POST concluído, mas nenhum sistema inicializável foi encontrado.|POST complete, but no bootable system was found.|POST completo, pero no se encontró un sistema de arranque.
POST com falha de vídeo: o monitor detectou artefatos e perda intermitente de sinal.|POST video failure: artifacts and intermittent signal loss detected.|Fallo de vídeo en POST: se detectaron artefactos y pérdida intermitente de señal.
Falha no POST: |POST failure: |Fallo de POST: 
Falha no POST: erros detectados em ram |POST failure: errors detected in RAM |Fallo de POST: se detectaron errores en RAM 
Componente essencial ausente — RAM: instale um módulo em A1 ou A2.|Missing essential component — RAM: install a module in A1 or A2.|Falta un componente esencial — RAM: instala un módulo en A1 o A2.
Coloque um computador físico na bancada para liberar os testes.|Place a PC on the workbench to enable tests.|Coloca un PC en el banco para habilitar las pruebas.
Coloque um computador físico na bancada.|Place a PC on the workbench.|Coloca un PC en el banco.
Coloque um computador na bancada.|Place a computer on the workbench.|Coloca un equipo en el banco.
Coloque um equipamento para executar a verificação de inicialização.|Place a PC to run the startup check.|Coloca un PC para ejecutar la prueba de inicio.
Os resultados aparecerão depois que um equipamento for colocado e testado.|Results appear after placing and testing a PC.|Los resultados aparecen al colocar y probar un PC.
Verificando %s · %.1f s restantes|Testing %s · %.1f s left|Probando %s · quedan %.1f s
Inspeção, desmontagem e testes de componentes.|Inspection, disassembly, and component tests.|Inspección, desmontaje y pruebas de componentes.
Indicadores de operação. Nenhum teste foi executado.|Operational indicators. No tests have been run.|Indicadores de funcionamiento. Aún no se han ejecutado pruebas.
Verificações básicas da bancada. Resultados ficam salvos em cada peça.|Workbench checks. Results are saved on each part.|Pruebas del banco. Los resultados se guardan en cada pieza.
Clique em Iniciar POST|Select Run POST|Pulsa Ejecutar POST
Teste térmico indisponível|Thermal test unavailable|Prueba térmica no disponible
Verificação de inicialização (POST)|Startup check (POST)|Comprobación de inicio (POST)
Teste disponível também na aba Testes. Nenhuma peça é corrigida automaticamente.|Also available in the Tests tab. Testing leaves parts in their current condition.|También disponible en la pestaña Pruebas. La prueba conserva el estado de las piezas.
Pronto para testar a RAM. O teste revela sua condição e não realiza reparos.|Ready to test RAM. The test reports the module's condition.|Memoria lista para probar. La prueba indica el estado del módulo.
Ligue o PC ou clique em Iniciar POST antes de testar a RAM.|Power on the PC or run POST before testing RAM.|Enciende el PC o ejecuta el POST antes de probar la RAM.
Aguarde o término do POST para testar a RAM.|Wait for POST to finish before testing RAM.|Espera a que termine el POST antes de probar la RAM.
Ligue o computador e aguarde o POST antes do teste.|Power on the computer and wait for POST before testing.|Enciende el equipo y espera al POST antes de probar.
Teste em andamento. Aguarde ou desligue o PC para cancelar.|Test in progress. Wait or shut down the PC to cancel.|Prueba en curso. Espera o apaga el PC para cancelar.
Fixe e reconecte a peça antes do teste.|Secure and reconnect the part before testing.|Fija y vuelve a conectar la pieza antes de probarla.
Ligue o PC para acessar a tela do cliente.|Power on the PC to view the customer's screen.|Enciende el PC para ver la pantalla del cliente.
○  EQUIPAMENTO ASSOCIADO|○  EQUIPMENT DOCKED|○  EQUIPO COLOCADO
Equipamento físico associado à área de apoio.|Physical equipment docked on the workbench.|Equipo físico colocado en el banco.
Coloque um equipamento físico na bancada para consultar seus dados.|Place a PC on the workbench to see its details.|Coloca un PC en el banco para consultar sus datos.
Indisponíveis enquanto a bancada estiver vazia.|Unavailable while the workbench is empty.|No disponible mientras el banco esté vacío.
Operação ainda não implementada.|Operation unavailable.|Operación no disponible.
Nenhum teste executado|No tests performed|Sin pruebas realizadas
Nenhum diagnóstico executado.|No diagnostics performed.|Sin diagnóstico realizado.
Sem diagnóstico ou testes executados|No diagnostics or tests performed|Sin diagnóstico ni pruebas realizadas
Use Inspecionar para acessar o equipamento compatível.|Select Inspect to access the compatible equipment.|Pulsa Inspeccionar para acceder al equipo compatible.
A visualização fica oculta até um equipamento ser colocado na bancada.|The view is hidden until a PC is placed on the workbench.|La vista permanece oculta hasta colocar un PC en el banco.
ESTABILIDADE|STABILITY|ESTABILIDAD
CONDIÇÃO ATUAL|CURRENT CONDITION|ESTADO ACTUAL
Estado e situação de manutenção|Condition and repair status|Estado de conservación y reparación
IDENTIFICAÇÃO|IDENTIFICATION|IDENTIFICACIÓN
Nome, modelo e número de série|Name, model, and serial number|Nombre, modelo y número de serie
VISUALIZAÇÃO DO PC|PC PREVIEW|VISTA DEL PC
Sem equipamento|No equipment|Sin equipo
Problemas e observações identificados durante a análise.|Problems and observations found during analysis.|Problemas y observaciones identificados durante el análisis.
Estrutura de peças do equipamento em manutenção.|Parts installed in the equipment being serviced.|Piezas instaladas en el equipo en reparación.
Identificação, condição e visualização do equipamento.|Equipment identification, condition, and preview.|Identificación, estado y vista del equipo.
Aguardando equipamento para análise.|Waiting for equipment to analyze.|Esperando equipo para analizar.
Selecionado|Selected|Seleccionado
SELECIONADO|SELECTED|SELECCIONADO
Nenhuma peça selecionada|No part selected|Ninguna pieza seleccionada
Passe o mouse sobre o gabinete.|Hover over the case.|Pasa el ratón sobre la caja.
Fixado|Fastened|Fijado
Retirado|Removed|Retirado
Nenhum equipamento|No equipment|Sin equipo
COMPUTADOR PESSOAL  /  TECHOS|PERSONAL COMPUTER  /  TECHOS|EQUIPO PERSONAL  /  TECHOS
SISTEMA LOCAL DA OFICINA|WORKSHOP LOCAL SYSTEM|SISTEMA LOCAL DEL TALLER
DESLIGADO|OFF|APAGADO
TechOS pronto|TechOS ready|TechOS listo
Inicializando o computador…|Starting computer…|Iniciando equipo…
Inicializando o TechOS…|Starting TechOS…|Iniciando TechOS…
Preparando o ambiente local…|Preparing the local environment…|Preparando el entorno local…
Carregando a área de trabalho…|Loading the desktop…|Cargando el escritorio…
Use Ligar computador para iniciar o ambiente de administração.|Select Power on computer to start the workshop system.|Pulsa Encender equipo para iniciar el sistema del taller.
Você pode desligar ou fechar a tela durante a inicialização.|You can shut down or close the screen during startup.|Puedes apagar o cerrar la pantalla durante el inicio.
Ambiente local · Aplicativo em preparação|Local environment · App under development|Entorno local · Aplicación en desarrollo
Aplicativo em preparação.|App under development.|Aplicación en desarrollo.
Nenhum dado disponível|No data available|No hay datos disponibles
Propostas de clientes|Customer offers|Ofertas de clientes
Fila de serviços|Work queue|Cola de trabajos
Entregas concluídas|Completed deliveries|Entregas completadas
Moderno|Modern|Moderno
Madeira clara|Light wood|Madera clara
Madeira escura|Dark wood|Madera oscura
Rústico|Rustic|Rústico
Concreto|Concrete|Hormigón
Mármore|Marble|Mármol
%d / 4 parafusos retirados|%d / 4 screws removed|%d / 4 tornillos retirados
retirada do PC|removed from PC|retirada del PC
kit recebido|starter kit|kit recibido
comprada|purchased|comprada
Soquete %s|Socket %s|Zócalo %s
Selecione a chave Phillips e clique nos parafusos.|Select the Phillips screwdriver and click the screws.|Selecciona el destornillador Phillips y pulsa los tornillos.
Desligado e sem alimentação. Clique diretamente no gabinete.|Powered off. Click directly on the case.|Apagado. Pulsa directamente la caja.
Coloque um equipamento físico na bancada para inspecionar.|Place a PC on the workbench to inspect it.|Coloca un PC en el banco para inspeccionarlo.
1 · Mãos: peças e conectores↵Roda: zoom · Meio: arrastar↵Botão direito: restaurar vista↵2 · Phillips: parafusos↵Ciano: conectado · Âmbar: solto↵Clique nos pontos do gabinete.|1 · Hands: parts and connectors↵Wheel: zoom · Middle button: pan↵Right button: reset view↵2 · Phillips: screws↵Cyan: connected · Amber: loose↵Click the points on the case.|1 · Manos: piezas y conectores↵Rueda: zoom · Botón central: desplazar↵Botón derecho: restaurar vista↵2 · Phillips: tornillos↵Cian: conectado · Ámbar: suelto↵Pulsa los puntos de la caja.
Fechar bancada (ESC)|Close workbench (Esc)|Cerrar banco (Esc)
Fechar (ESC)|Close (Esc)|Cerrar (Esc)
Computador pessoal do jogador • Separado dos equipamentos em manutenção|Player's personal computer • Separate from equipment under repair|Equipo personal del jugador • Separado de los equipos en reparación
Item ou destino inválido.|Invalid item or destination.|Artículo o destino no válido.
O destino deve ficar dentro da oficina.|The destination must be inside the workshop.|El destino debe estar dentro del taller.
Retire o componente ou aguarde a entrega antes de transportá-lo.|Remove the component or wait for delivery before carrying it.|Retira el componente o espera la entrega antes de transportarlo.
Desligue o computador antes de transportá-lo.|Turn off the computer before carrying it.|Apaga el equipo antes de transportarlo.
Inventário: até 3 peças; transporte gabinetes nas mãos.|Inventory holds up to 3 parts. Carry PCs by hand.|El inventario admite hasta 3 piezas. Lleva los equipos en la mano.
Você só pode carregar um item por vez.|You can carry only one item at a time.|Solo puedes llevar un artículo a la vez.
A bancada já está ocupada ou o item não é um gabinete.|The workbench is occupied or the item is not a PC.|El banco está ocupado o el artículo no es un PC.
A bandeja aceita até quatro componentes.|The tray holds up to four components.|La bandeja admite hasta cuatro componentes.
Embalagem aberta. O componente continua aqui: pressione E para pegá-lo.|Package opened. Press E to pick up the component.|Paquete abierto. Pulsa E para recoger el componente.
Desligue o computador antes de tocar na tampa, travas ou componentes.|Turn off the PC before touching the panel, latches, or components.|Apaga el PC antes de tocar el panel, los cierres o los componentes.
Retire a tampa lateral.|Remove the side panel.|Retira el panel lateral.
Retire a tampa para acessar as fixações.|Remove the panel to access the fasteners.|Retira el panel para acceder a las fijaciones.
Instale a placa-mãe primeiro.|Install the motherboard first.|Instala primero la placa base.
Instale a placa-mãe para acessar o slot de RAM.|Install the motherboard to access the RAM slot.|Instala la placa base para acceder a la ranura de RAM.
Instale a placa-mãe para acessar as travas da RAM.|Install the motherboard to access the RAM latches.|Instala la placa base para acceder a los cierres de RAM.
Retire a tampa antes de abrir as travas da RAM.|Remove the panel before opening the RAM latches.|Retira el panel antes de abrir los cierres de RAM.
Abra as duas travas deste slot antes de retirar ou encaixar a RAM.|Open both latches before removing or inserting RAM.|Abre ambos cierres antes de quitar o insertar la RAM.
RAM encaixada. Feche as duas travas antes de ligar o computador.|RAM installed. Close both latches before powering on the PC.|RAM instalada. Cierra ambos cierres antes de encender el PC.
Bandeja e inventário cheios. Guarde peças no armário.|Tray and inventory are full. Store parts in the cabinet.|La bandeja y el inventario están llenos. Guarda piezas en el armario.
Nenhum computador na bancada.|No computer on the workbench.|No hay equipo en el banco.
Coloque um computador na bancada antes de testar.|Dock a computer before testing.|Coloca un equipo en el banco antes de probar.
Aguarde o teste de componente em andamento.|Wait for the component test to finish.|Espera a que finalice la prueba del componente.
Aguarde o POST em andamento.|Wait for POST to finish.|Espera a que finalice el POST.
POST iniciado. Aguarde a verificação dos componentes instalados.|POST started. Wait for the installed components to be checked.|POST iniciado. Espera a que se comprueben los componentes instalados.
Produto indisponível.|Product unavailable.|Producto no disponible.
Este componente não oferece escolha de cor.|This part has no color options.|Esta pieza no ofrece opciones de color.
Cor de dissipador indisponível.|Heat spreader color unavailable.|Color de disipador no disponible.
Créditos insuficientes. Nenhuma compra realizada.|Insufficient funds. Purchase canceled.|Fondos insuficientes. Compra cancelada.
Compra registrada. A caixa chegará em três segundos.|Purchase placed. The package will arrive in three seconds.|Compra registrada. El paquete llegará en tres segundos.
Entrega recebida. Abra a caixa com E.|Delivery received. Press E to open the package.|Entrega recibida. Pulsa E para abrir el paquete.
Selecione Mãos (1) para manusear peças.|Select Hands (1) to handle parts.|Selecciona Manos (1) para manipular piezas.
Selecione Mãos (1) para operar conectores e travas.|Select Hands (1) to operate connectors and latches.|Selecciona Manos (1) para manipular conectores y cierres.
Selecione a Phillips (2) para operar este parafuso.|Select Phillips (2) to turn this screw.|Selecciona Phillips (2) para girar este tornillo.
Encaixe o processador antes do cooler.|Install the processor before the cooler.|Instala el procesador antes del disipador.
Selecione uma peça compatível no inventário da inspeção.|Select a compatible part in the inspection inventory.|Selecciona una pieza compatible en el inventario de inspección.
Novo cliente: uma proposta chegou ao balcão de atendimento.|New customer: an offer has arrived at the service counter.|Nuevo cliente: llegó una oferta al mostrador.
Esta proposta não está disponível.|This offer is unavailable.|Esta oferta no está disponible.
Libere espaço no balcão de atendimento.|Clear space on the service counter.|Libera espacio en el mostrador.
Somente propostas podem ser recusadas.|Only offers can be declined.|Solo se pueden rechazar ofertas.
Proposta recusada. Outro cliente poderá chegar em breve.|Offer declined. Another customer may arrive soon.|Oferta rechazada. Pronto puede llegar otro cliente.
Este pedido não está em andamento.|This job is not active.|Este pedido no está activo.
A placa não gera sinal.|The card produces no signal.|La tarjeta no genera señal.
Artefatos e perda intermitente de sinal.|Artifacts and intermittent signal loss.|Artefactos y pérdida intermitente de señal.
Saída da placa estável.|Stable graphics output.|Salida de vídeo estable.
Peça selecionada. Com Mãos, clique no encaixe vazio correspondente; depois fixe e reconecte.|Part selected. Use Hands to click its empty mount, then fasten and reconnect it.|Pieza seleccionada. Con Manos, pulsa el hueco correspondiente y después fíjala y conéctala.
Diagnóstico de memória após o POST; também identifica módulos defeituosos que impedem o boot.|Memory diagnostics after POST also identify faulty modules that prevent booting.|El diagnóstico tras el POST también identifica módulos defectuosos que impiden arrancar.
Nenhum equipamento na bancada.|No equipment on the workbench.|No hay equipo en el banco.
Use a Phillips para soltar ou fixar.|Use Phillips to loosen or fasten.|Usa el destornillador Phillips para soltar o fijar.
Retirada e apoiada ao lado.|Removed and set aside.|Retirada y colocada a un lado.
Retire os quatro parafusos para liberar.|Remove all four screws to release it.|Retira los cuatro tornillos para liberarla.
Libere parafusos, conectores e travas antes de retirar. CPU: alavanca do socket, sem parafusos.|Release screws, connectors, and latches before removal. CPUs use a socket lever.|Libera los tornillos, conectores y cierres antes de retirar. El procesador usa una palanca.
Selecione Mãos para operar as travas sem danificar a RAM.|Select Hands to release latches safely.|Selecciona Manos para abrir los cierres sin dañar la RAM.
Selecione Mãos para retirar ou encaixar um módulo de RAM.|Select Hands to remove or install a RAM module.|Selecciona Manos para retirar o instalar un módulo de RAM.
Abra a caixa de ferramentas da oficina com F para obter acesso à Phillips.|Open the workshop toolbox with F to unlock Phillips.|Abre la caja de herramientas con F para desbloquear el destornillador Phillips.
Phillips (2): clique nos parafusos da tampa ou de cada componente.|Phillips (2): click the screws on the panel or component.|Phillips (2): pulsa los tornillos del panel o del componente.
Recoloque a tampa antes de fixar seus parafusos.|Reattach the panel before fastening its screws.|Coloca el panel antes de fijar sus tornillos.
Selecione a chave Phillips para soltar ou fixar este parafuso.|Select the Phillips screwdriver to loosen or fasten this screw.|Selecciona el destornillador Phillips para soltar o fijar este tornillo.
Parafuso %d fixado na tampa.|Screw %d fastened in the panel.|Tornillo %d fijado en el panel.
Os quatro parafusos foram retirados. Clique na tampa para removê-la.|All four screws are out. Click the panel to remove it.|Se retiraron los cuatro tornillos. Pulsa el panel para retirarlo.
Parafuso %d retirado. Faltam %d para liberar a tampa.|Screw %d removed. Remove %d more to release the panel.|Tornillo %d retirado. Faltan %d para liberar el panel.
A tampa ainda está presa: retire os %d parafuso(s) restantes com a chave Phillips.|The panel is still attached. Remove the remaining %d screw(s) with Phillips.|El panel sigue sujeto. Retira los %d tornillos restantes con el destornillador Phillips.
Tampa recolocada, ainda sem fixação. Use a Phillips nos quatro pontos para prender a tampa.|Panel reattached. Use Phillips at all four points to secure it.|Panel colocado. Usa el destornillador Phillips en los cuatro puntos para fijarlo.
Tampa retirada. Selecione Mãos, abra as duas travas da RAM e clique no módulo.|Panel removed. Select Hands, open both RAM latches, and click the module.|Panel retirado. Selecciona Manos, abre los dos cierres de RAM y pulsa el módulo.
Tampa retirada e apoiada ao lado. Passe o mouse sobre as peças para identificá-las.|Panel removed and set aside. Hover over parts to identify them.|Panel retirado y apartado. Pasa el ratón sobre las piezas para identificarlas.
Retire a tampa para acessar os componentes internos.|Remove the panel to access internal components.|Retira el panel para acceder a los componentes internos.
Componente selecionado. Apenas identificação visual está disponível nesta etapa.|Component selected. Only visual identification is available at this stage.|Componente seleccionado. En esta fase solo se puede identificar visualmente.
As conversas simuladas da oficina aparecerão aqui.↵O aplicativo ainda não possui mensagens ou conexão externa.|Simulated workshop conversations will appear here.↵Messaging is currently unavailable.|Aquí aparecerán las conversaciones simuladas del taller.↵La mensajería aún no está disponible.
Nenhum cliente cadastrado|No customers registered|No hay clientes registrados
Este espaço está preparado para os futuros clientes e pedidos de manutenção.↵Nenhum cadastro foi criado.|This space is reserved for customers and repair orders.↵There are no records yet.|Este espacio está reservado a clientes y órdenes de reparación.↵Aún no hay registros.
Catálogo indisponível|Catalog unavailable|Catálogo no disponible
A loja de peças será disponibilizada em uma etapa futura.↵Nenhuma compra pode ser realizada.|The parts store is unavailable here.↵Purchases are unavailable.|La tienda de piezas no está disponible aquí.↵No se pueden realizar compras.
Extrato em preparação|Statement in preparation|Extracto en preparación
O relatório financeiro detalhado ainda não foi implementado.↵As compras de RAM são debitadas no saldo do TechMarket.|Detailed financial reporting is unavailable.↵RAM purchases are charged to the TechMarket balance.|El informe financiero detallado aún no está disponible.↵Las compras de RAM se descuentan del saldo de TechMarket.
Um espaço para as futuras ações de divulgação da oficina.↵Nenhuma campanha está ativa.|A space for future workshop promotions.↵There are no active campaigns.|Un espacio para futuras promociones del taller.↵No hay campañas activas.
Esta pasta está vazia|This folder is empty|Esta carpeta está vacía
Os arquivos fictícios do jogo ficarão organizados aqui.↵Este aplicativo não acessa os arquivos reais do computador.|Fictional game files will appear here.↵This app uses only in-game files.|Aquí aparecerán los archivos ficticios del juego.↵Esta aplicación solo usa archivos del juego.
Ordens de serviço · Recebimento e entrega no balcão|Work orders · Receive and deliver at the counter|Órdenes de servicio · Recepción y entrega en el mostrador
TechMarket · Compras locais e entregas físicas|TechMarket · Local purchases and deliveries|TechMarket · Compras locales y entregas
Abrir a inspeção para desmontar e encaixar peças manualmente.|Open inspection to remove and install parts by hand.|Abre la inspección para desmontar e instalar las piezas manualmente.
Avaliar a RAM instalada, mesmo se ela impedir a inicialização do sistema.|Test installed RAM even when it prevents the system from starting.|Prueba la RAM instalada incluso si impide arrancar el sistema.
Verifique a saída de vídeo e exiba um padrão de cores quando o sinal estiver estável.|Check video output and show a color pattern when the signal is stable.|Comprueba la salida de vídeo y muestra un patrón de colores cuando la señal sea estable.
Este equipamento ainda não possui um perfil de inspeção compatível.|This equipment has no compatible inspection profile yet.|Este equipo aún no tiene un perfil de inspección compatible.
Inspeção visual disponível. Reparos e testes indisponíveis.|Visual inspection is available. Repairs and tests are unavailable.|Inspección visual disponible. Reparaciones y pruebas no disponibles.
Perfil de inspeção não disponível para este equipamento.|No inspection profile is available for this equipment.|No hay un perfil de inspección disponible para este equipo.
Proprietário: %s|Owner: %s|Propietario: %s
Abrir inspeção visual|Open visual inspection|Abrir inspección visual
Indisponível: coloque um equipamento físico compatível na bancada.|Unavailable: place compatible equipment on the workbench.|No disponible: coloca un equipo compatible en el banco.
Indisponível: nenhum equipamento na bancada.|Unavailable: no equipment on the workbench.|No disponible: no hay equipo en el banco.
Aplicar cor #%s|Apply color #%s|Aplicar color #%s
Voltar ao jogo sem desligar o TechOS (ESC)|Return to the game while TechOS keeps running (Esc)|Vuelve al juego con TechOS encendido (Esc)
Desligar o computador e devolver o controle ao personagem|Shut down the PC and return to the player|Apagar el equipo y devolver el control al personaje
Voltar sem perder o estado da inspeção (ESC)|Return without losing inspection progress (Esc)|Vuelve sin perder el progreso de inspección (Esc)
Selecionar chave Phillips para soltar ou fixar parafusos|Select Phillips to loosen or fasten screws|Selecciona Phillips para soltar o fijar tornillos
Selecionar mãos livres|Select bare hands|Seleccionar manos libres
Use a Phillips nos quatro parafusos da tampa.|Use Phillips on the four panel screws.|Usa Phillips en los cuatro tornillos del panel.
Também é possível clicar na própria tampa|You can also click the panel itself|También puedes pulsar directamente el panel
Solte os quatro parafusos com a Phillips antes de retirar a tampa.|Loosen all four screws with Phillips before removing the panel.|Afloja los cuatro tornillos con Phillips antes de retirar el panel.
Selecione a chave Phillips e clique em um dos quatro parafusos.|Select Phillips and click one of the four screws.|Selecciona Phillips y pulsa uno de los cuatro tornillos.
As informações ficam disponíveis quando há um computador nesta bancada.|Details are available when a computer is on this workbench.|Los datos están disponibles cuando hay un equipo en este banco.
A visualização ficará disponível com um equipamento.|The preview is available when equipment is docked.|La vista estará disponible cuando coloques un equipo.
Indisponível: não há equipamento na bancada.|Unavailable: no equipment on the workbench.|No disponible: no hay equipo en el banco.
Nenhuma análise foi executada. Os problemas identificados serão exibidos aqui, sem resultados presumidos.|No analysis has run. Identified problems will appear here.|Aún no se ha realizado un análisis. Aquí aparecerán los problemas detectados.
Temperatura, estabilidade e funcionamento serão apresentados somente após a execução dos testes.|Temperature, stability, and operation appear after running tests.|La temperatura, la estabilidad y el funcionamiento aparecen tras las pruebas.
INICIALIZANDO|STARTING|INICIANDO
LIGADO|ON|ENCENDIDO
Nenhuma conversa|No conversations|Ninguna conversación
Nenhuma campanha|No campaigns|Ninguna campaña
Conclua um serviço: a fila aceita até três pedidos ativos.|Finish a job first. The queue holds up to three active jobs.|Termina un trabajo primero. La cola admite hasta tres trabajos activos.
%s movido para o início da fila.|%s moved to the front of the queue.|%s pasó al inicio de la cola.
Entrega pendente: %s.|Pending delivery: %s.|Entrega pendiente: %s.
%s · parafuso %d do suporte TRASEIRO · %s|%s · REAR bracket screw %d · %s|%s · tornillo %d del soporte TRASERO · %s
Parafuso %d|Screw %d|Tornillo %d
Parafuso %d — %s|Screw %d — %s|Tornillo %d — %s
fixado|fastened|fijado
retirado|removed|retirado
solto|loose|suelto
retirado; clique para fixar|removed; click to fasten|retirado; pulsa para fijar
conectado / travado|connected / locked|conectado / bloqueado
liberado|released|liberado
superior|upper|superior
inferior|lower|inferior
fechada|closed|cerrado
aberta|open|abierto
RAM A2 · trava %s · %s|RAM A2 · %s latch · %s|RAM A2 · cierre %s · %s
Trava %s da RAM — %s|RAM %s latch — %s|Cierre %s de RAM — %s
RAM A2 · slot vazio — selecione uma RAM e clique|RAM A2 · empty slot — select RAM and click|RAM A2 · ranura vacía — selecciona la memoria y pulsa
Slot RAM A1 vazio — selecione um módulo e clique para encaixar|RAM A1 empty — select a module and click to install|RAM A1 vacía — selecciona un módulo y pulsa para instalar
Encaixe vazio — selecione a peça e clique para instalar|Empty mount — select the part and click to install|Hueco vacío — selecciona la pieza y pulsa para instalar
Instale a placa-mãe.|Install the motherboard.|Instala la placa base.
Tampa lateral|Side panel|Panel lateral
Tampa retirada — clique para recolocar|Panel removed — click to put it back|Panel retirado — pulsa para colocarlo
energia|power|alimentación
trava PCIe|PCIe latch|cierre PCIe
SATA dados|SATA data|datos SATA
SATA energia|SATA power|alimentación SATA
chicote de energia|power harness|mazo de alimentación
painel frontal|front panel|panel frontal
Mãos (1): conectores, travas, peças e encaixes. Libere as fixações antes de retirar.|Hands (1): connectors, latches, parts, and mounts. Release fasteners before removal.|Manos (1): conectores, cierres, piezas y huecos. Suelta las fijaciones antes de retirar.
Mãos livres. Clique na tampa para manuseá-la.|Hands selected. Click the panel to handle it.|Manos seleccionadas. Pulsa el panel para manipularlo.
Primeira ordem guiada|Guided first job|Primera orden guiada
Use WASD para ir ao balcão marcado. Pressione F e escolha Receber serviço na ordem guiada.|Use WASD to go to the marked counter. Press F and choose Accept job on the guided order.|Usa WASD para ir al mostrador marcado. Pulsa F y elige Aceptar servicio en la orden guiada.
Vá à caixa de ferramentas junto ao armário e pressione F para pegar a chave Phillips.|Go to the toolbox by the cabinet and press F to get the Phillips screwdriver.|Ve a la caja de herramientas junto al armario y pulsa F para coger el destornillador Phillips.
Feche a bancada e abra a caixa de ferramentas junto ao armário com F.|Close the workbench and press F at the toolbox by the cabinet.|Cierra el banco y abre la caja de herramientas junto al armario con F.
Aproxime-se do gabinete do cliente e pressione E para pegá-lo.|Approach the customer's PC and press E to pick it up.|Acércate al PC del cliente y pulsa E para recogerlo.
A bancada está ocupada. Deixe este gabinete no chão com E e libere a bancada.|The workbench is occupied. Press E to set this PC down on the floor, then clear the bench.|El banco está ocupado. Pulsa E para dejar este PC en el suelo y despeja el banco.
Leve o gabinete até a bancada marcada e pressione E para colocá-lo no tampo.|Carry the PC to the marked workbench and press E to set it down.|Lleva el PC al banco marcado y pulsa E para colocarlo encima.
Aproxime-se da bancada e pressione F para abrir a manutenção.|Approach the workbench and press F to open the repair interface.|Acércate al banco y pulsa F para abrir el panel de reparación.
Clique em Inspecionar para continuar o conserto do PC.|Click Inspect to continue repairing the PC.|Haz clic en Inspeccionar para continuar la reparación del PC.
Volte à inspeção para continuar o conserto do PC.|Return to inspection to continue repairing the PC.|Vuelve a la inspección para continuar la reparación del PC.
Clique em Ligar PC para verificar a inicialização do gabinete do cliente.|Click Power on PC to check whether the customer's PC starts.|Haz clic en Encender PC para comprobar el arranque del equipo del cliente.
Aguarde a verificação de inicialização (POST).|Wait for the startup check (POST).|Espera a que termine la comprobación de arranque (POST).
Clique em Testar RAM para identificar o problema de memória, mesmo com o POST falhando.|Click Test RAM to identify the memory problem even though POST failed.|Haz clic en Probar RAM para identificar el problema de memoria aunque falle el POST.
Clique em Desligar PC antes de mexer no gabinete.|Click Power off PC before working on the case.|Haz clic en Apagar PC antes de manipular la caja.
Feche a bancada para buscar uma RAM DDR4 de reposição.|Close the workbench to get replacement DDR4 RAM.|Cierra el banco para buscar memoria DDR4 de repuesto.
Pressione F no computador da oficina. Ligue-o e compre RAM DDR4 em Loja de Peças.|Press F at the workshop computer. Power it on and buy DDR4 RAM from the Parts Shop.|Pulsa F en el ordenador del taller. Enciéndelo y compra memoria DDR4 en la Tienda de piezas.
Abra Loja de Peças no TechOS e compre uma RAM DDR4. A entrega chega na área de recebimento.|Open the Parts Shop in TechOS and buy DDR4 RAM. The package arrives in the receiving area.|Abre la Tienda de piezas en TechOS y compra memoria DDR4. El paquete llega a la zona de recepción.
Feche o TechOS com Esc e siga o marcador para buscar a RAM DDR4.|Close TechOS with Esc and follow the marker to pick up the DDR4 RAM.|Cierra TechOS con Esc y sigue el marcador para recoger la memoria DDR4.
A RAM DDR4 foi comprada. Aguarde a caixa chegar à área de recebimento.|DDR4 RAM purchased. Wait for the package to arrive in the receiving area.|Memoria DDR4 comprada. Espera a que el paquete llegue a la zona de recepción.
Vá até a entrega e pressione E para abrir a caixa de RAM DDR4.|Go to the delivery and press E to open the DDR4 RAM package.|Ve al paquete y pulsa E para abrir la caja de memoria DDR4.
Pressione E ao lado da RAM DDR4 desembalada para pegá-la.|Press E beside the unpacked DDR4 RAM to pick it up.|Pulsa E junto a la memoria DDR4 desembalada para recogerla.
Vá ao armário, pressione F e mova a RAM DDR4 do armário para o inventário.|Go to the cabinet, press F, and move the DDR4 RAM from the cabinet to your inventory.|Ve al armario, pulsa F y pasa la memoria DDR4 del armario al inventario.
Leve a RAM até a bancada e pressione E para colocá-la na bandeja. Depois pressione F.|Carry the RAM to the workbench and press E to put it in the tray. Then press F.|Lleva la memoria al banco y pulsa E para dejarla en la bandeja. Después pulsa F.
Selecione Phillips (2) e clique nos quatro parafusos da tampa para soltá-los.|Select the Phillips screwdriver (2) and click the four panel screws to remove them.|Selecciona Phillips (2) y haz clic en los cuatro tornillos del panel para retirarlos.
Clique em Retirar tampa para acessar os componentes.|Click Remove panel to access the components.|Haz clic en Retirar panel para acceder a los componentes.
Selecione Mãos (1) e abra as duas travas do slot A1, ao lado do cooler.|Select Hands (1) and open both latches on slot A1 beside the cooler.|Selecciona Manos (1) y abre los dos cierres de la ranura A1 junto al ventilador.
Com Mãos (1), clique no módulo A1 para retirar a RAM defeituosa.|With Hands selected (1), click the A1 module to remove the faulty RAM.|Con Manos (1), haz clic en el módulo A1 para retirar la memoria defectuosa.
Role a coluna Ferramentas até Peças e selecione a RAM DDR4. Com Mãos (1), clique no slot A1 vazio.|Scroll down the Tools panel to Parts and select the DDR4 RAM. With Hands selected (1), click the empty A1 slot.|Desplázate por la columna Herramientas hasta Piezas y selecciona la memoria DDR4. Con Manos (1), haz clic en la ranura A1 vacía.
Aguardando teste ou manuseio do gabinete.|Waiting for a test or work on the case.|Esperando una prueba o una acción sobre la caja.
Com Mãos (1), clique no slot A1 vazio para instalar a RAM selecionada.|With Hands selected (1), click the empty A1 slot to install the selected RAM.|Con Manos (1), haz clic en la ranura A1 vacía para instalar la memoria seleccionada.
Selecione Mãos (1) e feche as duas travas do slot A1, ao lado do cooler.|Select Hands (1) and close both latches on slot A1 beside the cooler.|Selecciona Manos (1) y cierra los dos cierres de la ranura A1 junto al ventilador.
Clique em Ligar PC e confirme que o POST agora passa com a nova RAM.|Click Power on PC and make sure POST now passes with the new RAM.|Haz clic en Encender PC y comprueba que el POST termina correctamente con la memoria nueva.
Confira as peças e fixações indicadas no resultado do POST. Desligue o PC antes de ajustá-las.|Check the parts and fasteners listed in the POST result. Power off the PC before adjusting them.|Revisa las piezas y fijaciones indicadas en el resultado del POST. Apaga el PC antes de ajustarlas.
Ligue o PC para testar a RAM de reposição.|Power on the PC to test the replacement RAM.|Enciende el PC para probar la memoria de repuesto.
Clique em Testar RAM para registrar a condição do módulo novo.|Click Test RAM to record the condition of the new module.|Haz clic en Probar RAM para registrar el estado del nuevo módulo.
Clique em Desligar PC antes de fechar o gabinete.|Click Power off PC before closing the case.|Haz clic en Apagar PC antes de cerrar la caja.
Clique em Recolocar tampa para fechar o gabinete.|Click Refit panel to close the case.|Haz clic en Volver a colocar el panel para cerrar la caja.
Selecione Phillips (2) e fixe os quatro parafusos da tampa.|Select the Phillips screwdriver (2) and tighten the four panel screws.|Selecciona Phillips (2) y aprieta los cuatro tornillos del panel.
Gabinete pronto. Feche a bancada e pressione Shift+E para pegá-lo.|The PC is ready. Close the workbench and press Shift+E to pick it up.|El PC está listo. Cierra el banco y pulsa Shift+E para recogerlo.
Pegue o gabinete fechado com Shift+E e leve-o de volta ao balcão.|Press Shift+E to pick up the closed PC and take it back to the counter.|Pulsa Shift+E para recoger el PC cerrado y llévalo al mostrador.
Leve o gabinete ao balcão. Pressione F e escolha Entregar ao cliente.|Carry the PC to the counter. Press F and choose Return to customer.|Lleva el PC al mostrador. Pulsa F y elige Entregar al cliente.
reparos de fonte e vídeo|power supply and graphics repairs|reparaciones de fuente y vídeo
revisões completas e reparos combinados|full inspections and multi-fault repairs|revisiones completas y reparaciones combinadas
Conclua %d entregas para liberar %s e uma expansão do armário.|Complete %d deliveries to unlock %s and a cabinet expansion.|Completa %d entregas para desbloquear %s y una ampliación del armario.
Todos os tipos de serviço foram desbloqueados.|All job types are unlocked.|Se han desbloqueado todos los tipos de servicio.
Você desbloqueou %s e uma expansão do armário.|You unlocked %s and a cabinet expansion.|Has desbloqueado %s y una ampliación del armario.
Desbloqueia com %d entregas.|Unlocks after %d deliveries.|Se desbloquea con %d entregas.
Você pode usar %s na expansão. Os adiantamentos ficam reservados para os pedidos.|You can spend %s on the expansion. Deposits are reserved for customer jobs.|Puedes gastar %s en la ampliación. Los anticipos se reservan para los pedidos.
Esta expansão do armário não está disponível.|This cabinet expansion is unavailable.|Esta ampliación del armario no está disponible.
Armário ampliado para %d espaços.|Cabinet expanded to %d slots.|Armario ampliado a %d espacios.
Capacidade máxima do armário alcançada.|Cabinet is fully expanded.|Se ha alcanzado la capacidad máxima del armario.
Ampliar armário · %s|Expand cabinet · %s|Ampliar armario · %s
Amplie o armário de %d para %d espaços.|Expand the cabinet from %d to %d slots.|Amplía el armario de %d a %d espacios.
Ampliar o armário para %d espaços por %s?|Expand the cabinet to %d slots for %s?|¿Ampliar el armario a %d espacios por %s?
CONFIRMAR COMPRA / ARMÁRIO|CONFIRM PURCHASE / CABINET|CONFIRMAR COMPRA / ARMARIO
Gabinetes|PC Cases|Gabinetes
Pesquisar por nome, marca ou formato|Search by name, brand or form factor|Buscar por nombre, marca o formato
Nenhum produto encontrado.|No matching products.|No se encontraron productos.
ATX Aquário|ATX Aquarium|ATX Acuario
Grafite|Graphite|Grafito
Preto e vermelho|Black and red|Negro y rojo
Tampa de vidro|Glass side panel|Panel lateral de vidrio
Tampa de aço|Steel side panel|Panel lateral de acero
Acabamento: %s · %s|Finish: %s · %s|Acabado: %s · %s
Placas-mãe: %s|Motherboards: %s|Placas base: %s
Espaço para fonte: %s|Power supply bay: %s|Espacio para fuente: %s
Baias: %d × 2,5″ · %d × 3,5″|Bays: %d × 2.5″ · %d × 3.5″|Bahías: %d × 2,5″ · %d × 3,5″
Suporta %d ventoinha(s)|Supports up to %d fan(s)|Hasta %d ventilador(es)
Entrega embalada, gabinete vazio.|Ships boxed as an empty case.|Se entrega en caja como gabinete vacío.
Abra a embalagem antes de transportar o gabinete.|Unbox the case before carrying it.|Abre la caja antes de transportar el gabinete.
Libere espaço na área de recebimento antes de comprar.|Clear some space in the receiving area before purchasing.|Libera espacio en la zona de recepción antes de comprar.
F — Montagem de PC↵E — Pegar gabinete|F — PC assembly↵E — Pick up case|F — Montaje de PC↵E — Recoger gabinete
F — Montagem de PC|F — PC assembly|F — Montaje de PC
Gabinete|Case|Gabinete
Oficina|Workshop|Taller
Gabinete vazio|Empty case|Gabinete vacío
Montagem em andamento|Build in progress|Montaje en curso
Iniciar montagem|Start assembly|Iniciar montaje
Montagem de PC|PC assembly|Montaje de PC
Abra o gabinete e instale a placa-mãe e o processador da bandeja.|Open the case and install the motherboard and processor from the tray.|Abre el gabinete e instala la placa base y el procesador de la bandeja.
Instale a placa-mãe e o processador neste gabinete.|Install the motherboard and processor in this case.|Instala la placa base y el procesador en este gabinete.
Use Iniciar montagem para acessar o interior do gabinete.|Select Start assembly to access the inside of the case.|Pulsa Iniciar montaje para acceder al interior del gabinete.
Montagem de PC · %s|PC assembly · %s|Montaje de PC · %s
Voltar à bancada|Back to workbench|Volver al banco de trabajo
Bandeja da bancada|Workbench tray|Bandeja del banco
Tampa|Side panel|Panel lateral
Encaixe da placa-mãe|Motherboard mount|Anclaje de la placa base
Retirar tampa|Remove panel|Retirar panel
Parafuso %d · Phillips (2)|Screw %d · Phillips (2)|Tornillo %d · Phillips (2)
Soquete da CPU e fixação do cooler|CPU socket and cooler mount|Zócalo de CPU y anclaje del disipador
Slots de memória RAM|RAM slots|Ranuras de memoria RAM
Slot PCIe para GPU|GPU PCIe slot|Ranura PCIe para GPU
Compartimento da fonte|Power supply bay|Bahía de la fuente
Baias de armazenamento|Drive bays|Bahías de almacenamiento
Solte os quatro parafusos com a Phillips. Depois use as mãos para retirar a tampa.|Loosen all four screws with the Phillips screwdriver, then remove the panel by hand.|Afloja los cuatro tornillos con la Phillips y retira el panel con las manos.
Traga uma placa-mãe desembalada à bandeja. Pegue-a com as mãos e clique ou arraste até o encaixe.|Bring an unboxed motherboard to the tray. Pick it up by hand, then click or drag it to the mount.|Lleva una placa base desembalada a la bandeja. Recógela con las manos y haz clic o arrástrala al anclaje.
Use a Phillips para fixar os parafusos da placa-mãe. Para retirar a peça, solte todos e use as mãos.|Use the Phillips screwdriver to fasten the motherboard screws. Loosen them all and use your hands to remove the board.|Fija los tornillos de la placa base con la Phillips. Para retirarla, aflójalos todos y usa las manos.
Placa-mãe fixada. O PC ainda precisa dos demais componentes essenciais para ligar.|Motherboard secured. The PC needs its remaining essential components before it can power on.|Placa base fijada. El PC aún necesita los demás componentes esenciales para encenderse.
Placa-mãe selecionada. Use as mãos no encaixe.|Motherboard selected. Use your hands on the mount.|Placa base seleccionada. Usa las manos en el anclaje.
Selecione Mãos (1) para manusear a tampa.|Select Hands (1) to handle the panel.|Selecciona Manos (1) para manipular el panel.
Tampa retirada. Pegue uma placa-mãe da bandeja e leve-a ao encaixe.|Panel removed. Pick a motherboard from the tray and move it to the mount.|Panel retirado. Recoge una placa base de la bandeja y llévala al anclaje.
Traga uma placa-mãe desembalada até a bandeja da bancada.|Bring an unboxed motherboard to the workbench tray.|Lleva una placa base desembalada a la bandeja del banco.
Formato incompatível: %s. Este gabinete aceita %s.|Incompatible form factor: %s. This case supports %s.|Formato incompatible: %s. Este gabinete admite %s.
Placa-mãe posicionada. Use a Phillips para fixar os parafusos.|Motherboard seated. Use the Phillips screwdriver to fasten the screws.|Placa base colocada. Usa la Phillips para fijar los tornillos.
Parafusos da placa-mãe fixados: %d de %d.|Motherboard screws fastened: %d of %d.|Tornillos de la placa base fijados: %d de %d.
Solte os %d parafuso(s) restantes da placa-mãe.|Loosen the remaining %d motherboard screw(s).|Afloja los %d tornillo(s) restantes de la placa base.
Libere um espaço na bandeja para retirar a placa-mãe.|Clear a tray slot before removing the motherboard.|Libera un espacio en la bandeja para retirar la placa base.
Placa-mãe retirada para a bandeja.|Motherboard returned to the tray.|Placa base retirada a la bandeja.
Nesta etapa da montagem, apenas a placa-mãe pode ser instalada.|This stage of assembly supports motherboard installation.|Esta etapa del montaje admite la instalación de la placa base.
Nesta etapa da montagem, apenas os parafusos da placa-mãe podem ser operados.|This stage supports working with the motherboard screws.|Esta etapa permite manipular los tornillos de la placa base.
Conclua a montagem e as conexões dos componentes essenciais antes de ligar o PC.|Install and connect the essential components before powering on the PC.|Monta y conecta los componentes esenciales antes de encender el PC.
Vender|Sell|Vender
Receba 90% do valor pago por cada item.|Receive 90% of what you paid for each item.|Recibe el 90 % de lo que pagaste por cada artículo.
Pesquisar seus itens|Search your items|Buscar tus artículos
Nenhum item comprado disponível para venda.|No purchased items are available to sell.|No hay artículos comprados disponibles para vender.
Nenhum item corresponde ao filtro.|No items match the filter.|Ningún artículo coincide con el filtro.
CONFIRMAR VENDA / TECHMARKET|CONFIRM SALE / TECHMARKET|CONFIRMAR VENTA / TECHMARKET
Recebe %s pela venda.|You receive %s for this sale.|Recibes %s por la venta.
Vender %s por %s?|Sell %s for %s?|¿Vender %s por %s?
Este item não está disponível para venda.|This item is unavailable for sale.|Este artículo no está disponible para la venta.
Este item já foi vendido.|This item has already been sold.|Este artículo ya se vendió.
Vendido: %s · %s recebidos.|Sold: %s · received %s.|Vendido: %s · recibiste %s.
Nas mãos|Carried|En las manos
Inventário|Inventory|Inventario
Bancada|Workbench|Banco de trabajo
Socket do processador|CPU socket|Zócalo del procesador
Abrir trava do socket|Open socket latch|Abrir cierre del zócalo
Fechar trava do socket|Close socket latch|Cerrar cierre del zócalo
Trava do socket aberta.|Socket latch open.|Cierre del zócalo abierto.
Processador travado no socket.|Processor locked in the socket.|Procesador fijado en el zócalo.
Processador encaixado. Feche a trava do socket.|Processor seated. Close the socket latch.|Procesador colocado. Cierra el cierre del zócalo.
Processador retirado para a bandeja.|Processor returned to the tray.|Procesador devuelto a la bandeja.
Retire o processador antes de retirar a placa-mãe.|Remove the processor before removing the motherboard.|Retira el procesador antes de retirar la placa base.
Abra a trava do socket antes de retirar o processador.|Open the socket latch before removing the processor.|Abre el cierre del zócalo antes de retirar el procesador.
Libere um espaço na bandeja para retirar o processador.|Clear a tray slot before removing the processor.|Libera espacio en la bandeja antes de retirar el procesador.
Traga um processador desembalado até a bandeja da bancada.|Bring an unboxed processor to the workbench tray.|Lleva un procesador desembalado a la bandeja del banco.
Socket incompatível: o processador usa %s e a placa-mãe usa %s.|Incompatible socket: the processor uses %s and the motherboard uses %s.|Zócalo incompatible: el procesador usa %s y la placa base usa %s.
Com Mãos (1), selecione ou arraste um processador da bandeja até o socket.|With Hands (1), select a processor or drag it from the tray to the socket.|Con Manos (1), selecciona un procesador o arrástralo de la bandeja al zócalo.
Clique na trava ao lado do socket para prender o processador.|Click the latch beside the socket to secure the processor.|Pulsa el cierre junto al zócalo para fijar el procesador.
Processador selecionado. Clique no socket.|Processor selected. Click the socket.|Procesador seleccionado. Pulsa el zócalo.
Processador travado. Para removê-lo, abra a trava do socket e clique no chip.|Processor locked. To remove it, open the socket latch and click the chip.|Procesador fijado. Para retirarlo, abre el cierre del zócalo y pulsa el chip.
Use os parafusos da placa-mãe ou a trava do socket nesta montagem.|Use the motherboard screws or the socket latch in this build.|Usa los tornillos de la placa base o el cierre del zócalo en este montaje.
Nesta etapa da montagem, é possível instalar a placa-mãe e o processador.|This stage supports motherboard and processor installation.|Esta etapa permite instalar la placa base y el procesador.
A instalação de RAM nesta montagem ainda não está disponível.|RAM installation is still unavailable for this build.|La instalación de RAM aún no está disponible en este montaje.
Adicionar gabinete|Add case|Añadir gabinete
Embalado|Boxed|Embalado
Compre um gabinete na Loja de Peças e aguarde a entrega.|Buy a case from the Parts Shop and wait for delivery.|Compra un gabinete en la Tienda de Piezas y espera la entrega.
Escolha um gabinete comprado para colocá-lo na bancada.|Choose a purchased case to place on the bench.|Elige un gabinete comprado para colocarlo en el banco.
Abra a inspeção para escolher um gabinete comprado.|Open inspection to choose a purchased case.|Abre la inspección para elegir un gabinete comprado.
Este gabinete ainda não está disponível para colocar na bancada.|This case is not available to place on the bench yet.|Este gabinete todavía no está disponible para colocarlo en el banco.
INSPEÇÃO VISUAL|VISUAL INSPECTION|INSPECCIÓN VISUAL
INSPEÇÃO VISUAL  /  %s|VISUAL INSPECTION  /  %s|INSPECCIÓN VISUAL  /  %s
Tampa retirada. Selecione uma peça e clique no encaixe.|Panel removed. Select a part and click its mount.|Panel retirado. Selecciona una pieza y pulsa su anclaje.
Instale o componente essencial antes de ligar: %s.|Install the required component before powering on: %s.|Instala el componente necesario antes de encender: %s.
Fixe e reconecte o componente antes de ligar: %s.|Secure and connect the component before powering on: %s.|Fija y conecta el componente antes de encender: %s."""

static func catalog() -> Dictionary:
	var messages := {"pt": {}, "en": {}, "es": {}}
	for line in ROWS.split("\n"):
		var fields := line.split("|")
		if fields.size() != 3: continue
		var original := fields[0].replace("↵", "\n")
		messages.pt[original] = original
		for i in range(1, 3):
			messages["en" if i == 1 else "es"][original] = fields[i].replace("↵", "\n")
	return messages
