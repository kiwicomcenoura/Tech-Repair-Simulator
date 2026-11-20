extends RefCounted
## Conversation rules for the fictional contacts, using the current workshop data.

const Prefs := preload("res://Scripts/UI/player_preferences.gd")
const Hardware := preload("res://Scripts/Equipment/hardware_catalog.gd")
const ACCENTS := {
	"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i",
	"ó": "o", "ô": "o", "õ": "o", "ú": "u", "ü": "u", "ç": "c",
}
const COMMON_WORDS := [
	"amdera", "intara", "core", "tr", "memory", "gb", "atx", "micro", "sata",
	"ssd", "pcie", "ddr3", "ddr4", "ddr5", "mm", "sem", "sistema", "w", "ram",
]


static func answer(ledger: RefCounted, entry: Dictionary, person: Dictionary, through: int) -> String:
	var outgoing: Array[String] = []
	for index in range(maxi(0, through - 24), through + 1):
		var message: Dictionary = entry.messages[index]
		if message.from == "player": outgoing.append(normalize(message.text))
	var text: String = outgoing.back()
	var topic := _topic(text)
	if topic == "thanks":
		return {"bia": "De nada! Me conta como ficou depois do teste.", "leo": "Por nada! Se precisar comparar outra peça, me manda o modelo.", "clara": "Eu que agradeço pela atenção! Pode me escrever quando tiver novidades."}.get(entry.contact, "Eu que agradeço! Se precisar de algum detalhe do meu computador, estou por aqui.")
	if topic == "greeting":
		var name: String = person.name.get_slice(" ", 0)
		if outgoing.size() > 1: return "Oi de novo! Pode continuar por aqui. O que você queria ver agora?"
		return "Oi! Aqui é %s. %s" % [name, _invitation(entry.contact, person.has("order"))]
	if topic == "personal":
		return {
			"bia": "Sou a Bia. Trabalho com montagem e diagnóstico, e gosto de descobrir por que uma máquina falhou no teste. Você está montando ou consertando um PC?",
			"leo": "Sou o Léo, do atendimento da TechMarket. Meu dia é cheio de pedidos de peças e entregas. Está procurando algo para uma montagem?",
			"clara": "Sou a Clara. Estou montando meu primeiro computador para estudar e ainda tenho dúvidas sobre as peças. Você pode me ajudar a escolher?",
		}.get(entry.contact, "Aqui é %s, da ordem %s. Posso te contar mais sobre o computador se precisar." % [person.name, person.role])
	if person.has("order"):
		return _customer(ledger, person.order, topic, text)
	var products := _products(ledger, text)
	if topic == "followup" or (topic == "other" and not products.is_empty()):
		for index in range(outgoing.size() - 2, -1, -1):
			var earlier_topic := _topic(outgoing[index])
			if earlier_topic in ["greeting", "thanks", "personal", "followup", "other"]: continue
			topic = earlier_topic
			break
	if products.is_empty():
		for index in range(outgoing.size() - 2, -1, -1):
			products = _products(ledger, outgoing[index])
			if not products.is_empty(): break
	if products.is_empty(): products = _products(ledger, normalize(entry.subject))
	if topic == "compatibility":
		_add_compatibility_context(ledger, products, outgoing)
	match entry.contact:
		"leo": return _market(ledger, topic, text, products)
		"bia": return _technician(topic, text, products)
		"clara": return _clara(topic, text)
	return _invitation(entry.contact, false)


static func normalize(value: String) -> String:
	var text := value.to_lower()
	for letter in ACCENTS: text = text.replace(letter, ACCENTS[letter])
	var cleaned := ""
	for character in text:
		var code: int = character.unicode_at(0)
		cleaned += character if (code >= 97 and code <= 122) or (code >= 48 and code <= 57) else " "
	return " ".join(cleaned.split(" ", false))


static func _has(text: String, terms: Array) -> bool:
	var boundary := " " + text + " "
	return terms.any(func(term: String) -> bool: return (" " + term + " ") in boundary)


static func _topic(text: String) -> String:
	if _has(text, ["preco", "valor", "custa", "custaria", "reais", "orcamento", "barato", "quanto", "precos"]):
		if not _has(text, ["tempo", "horas", "dias", "minutos", "prazo"]): return "price"
	if _has(text, ["prazo", "quando", "demora", "amanha", "horas", "dias", "tempo", "retirar", "buscar"]): return "deadline"
	if _has(text, ["compativel", "compatibilidade", "encaixa", "cabe", "serve", "socket", "soquete"]): return "compatibility"
	if _has(text, ["techos", "pendrive", "sistema", "formatar", "bios"]): return "system"
	if _has(text, ["entrega", "pedido", "comprei", "compro", "encomenda", "estoque", "disponivel", "comprar"]): return "delivery"
	if _has(text, ["problema", "sintoma", "defeito", "trava", "travando", "liga", "ligar", "video", "post", "diagnostico", "erro", "tela", "desliga", "barulho"]): return "symptom"
	if _has(text, ["memoria", "ram", "ddr3", "ddr4", "ddr5", "dual channel", "single channel"]): return "memory"
	if _has(text, ["conserto", "reparo", "pronto", "concluido", "andamento", "status", "terminou", "recebeu", "pc", "computador"]): return "progress"
	if _has(text, ["obrigado", "obrigada", "valeu", "agradeco", "brigadao"]): return "thanks"
	if _has(text, ["quem e voce", "seu nome", "o que voce faz", "sobre voce"]): return "personal"
	if text.split(" ", false).size() <= 5 and _has(text, ["oi", "ola", "bom dia", "boa tarde", "boa noite", "tudo bem", "como esta", "como voce esta"]): return "greeting"
	if _has(text, ["e esse", "e essa", "e agora", "como assim", "me explica", "por que", "qual deles", "e ai"]): return "followup"
	return "other"


static func _products(ledger: RefCounted, text: String) -> Array:
	var rank: Array = []
	for product in ledger.CATALOG:
		var name := normalize(product.model)
		var score := 0
		var found := {}
		for token in name.split(" ", false):
			if token.length() < 2 or found.has(token) or token in COMMON_WORDS: continue
			found[token] = true
			if _has(text, [token]): score += 3 if token.length() >= 4 or token.is_valid_int() else 1
		if score < 3: continue
		if _has(text, [name]): score += 10
		rank.append({"part": product, "score": score})
	rank.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return left.score > right.score)
	var result: Array = []
	for row in rank: result.append(row.part)
	return result


static func _add_compatibility_context(ledger: RefCounted, products: Array, outgoing: Array[String]) -> void:
	var kinds := products.map(func(part: Dictionary) -> String: return part.kind)
	for index in range(outgoing.size() - 2, -1, -1):
		if "motherboard" in kinds and ("cpu" in kinds or "ram" in kinds): return
		for part in _products(ledger, outgoing[index]):
			if part.kind in ["motherboard", "cpu", "ram"] and part.kind not in kinds:
				products.append(part)
				kinds.append(part.kind)


static func _invitation(id: String, customer: bool) -> String:
	if customer: return "Se quiser, posso explicar melhor o que acontece com o meu computador."
	return {
		"bia": "Quer uma segunda opinião sobre uma peça ou sobre o teste da máquina?",
		"leo": "Me diz qual peça você está procurando que eu confiro na TechMarket.",
		"clara": "Quero montar um computador para estudar. O que você sugere para começar?",
	}.get(id, "Como posso ajudar?")


static func _market(ledger: RefCounted, topic: String, text: String, products: Array) -> String:
	var part: Dictionary = {} if products.is_empty() else products[0]
	if topic in ["delivery", "deadline"]:
		if ledger.at("delivery").size() > 0:
			return "Tem %d entrega(s) a caminho agora. Quando as caixas chegarem, você pode retirar as peças na área de recebimento." % ledger.at("delivery").size()
		if not part.is_empty():
			return "Depois que você confirmar a compra de %s, a caixa chega na área de recebimento em cerca de três segundos." % part.model
		return "No momento não vejo nenhuma caixa a caminho. A entrega começa assim que você confirma a compra na TechMarket."
	if topic == "price":
		if not part.is_empty():
			return "Conferi agora: %s está por %s na TechMarket. Depois de confirmar a compra, a caixa vai para a área de recebimento." % [part.model, Prefs.money(part.price)]
		if _has(text, ["ddr3", "ddr4", "ddr5"]):
			for entry in ledger.CATALOG:
				if entry.kind == "ram" and _has(text, [entry.ddr.to_lower()]):
					return "A opção de entrada que achei foi %s por %s. Se você prefere outra capacidade, me diz quantos GB precisa." % [entry.model, Prefs.money(entry.price)]
		return "Posso conferir o preço e a entrega para você. Me passa o modelo da peça ou o tipo e a capacidade que procura."
	if topic == "compatibility": return _compatibility(products, text)
	if not part.is_empty(): return "Achei %s no catálogo. Quer saber o preço, a compatibilidade ou como funciona a entrega?" % part.model
	return "Posso te ajudar com peças, preço e entrega. Qual é o modelo ou o nome da peça que você tem em mente?"


static func _technician(topic: String, text: String, products: Array) -> String:
	match topic:
		"compatibility": return _compatibility(products, text)
		"memory":
			return "Começa pela geração que a placa aceita: DDR3, DDR4 e DDR5 têm encaixes diferentes. Para usar dois canais, coloque módulos em A e B. Numa placa de quatro slots, A2 e B2 são um bom ponto de partida."
		"system":
			return "Se passou no POST e o SSD está vazio, prepare o pendrive no Instalador TechOS da oficina. Depois conecte no PC da bancada, abra o monitor e selecione Iniciar pelo pendrive."
		"symptom":
			if _has(text, ["video", "tela", "imagem", "gpu"]):
				return "Se liga mas fica sem imagem, confirme se há vídeo integrado. Com um processador Intara da série F, por exemplo, você precisa de uma placa de vídeo dedicada. Depois confira as conexões da GPU."
			return "Eu começaria pelo POST da bancada. Se acusar memória, desligue o PC e confira se o módulo está encaixado com as duas travas fechadas. Que mensagem aparece no monitor?"
		"price", "delivery":
			return "Para preço ou entrega, o Léo da TechMarket consegue confirmar. Se me disser o modelo da placa e da peça, eu posso ajudar a conferir se combinam."
		_:
			if not products.is_empty(): return "Reconheci o modelo %s. Você quer saber se encaixa, como instalar ou o que testar?" % products[0].model
			return "Me passa o modelo da placa-mãe ou a mensagem que apareceu no POST. Com esse detalhe eu consigo te orientar melhor."


static func _compatibility(products: Array, text: String) -> String:
	var board: Dictionary = {}
	var cpu: Dictionary = {}
	var ram: Dictionary = {}
	for part in products:
		if part.kind == "motherboard" and board.is_empty(): board = part
		if part.kind == "cpu" and cpu.is_empty(): cpu = part
		if part.kind == "ram" and ram.is_empty(): ram = part
	if board.is_empty(): return "Qual é o modelo da placa-mãe? Com o nome completo eu consigo cruzar a geração, o soquete e o tipo de memória."
	if not cpu.is_empty():
		var reason := Hardware.cpu_reason(board, cpu)
		return "%s e %s são compatíveis nesta montagem." % [cpu.model, board.model] if reason.is_empty() else "%s com %s? %s" % [cpu.model, board.model, reason]
	if not ram.is_empty():
		return "%s usa %s. %s" % [board.model, board.ddr, "O módulo encaixa nesse padrão." if board.ddr == ram.ddr else "O módulo da sua mensagem usa %s, então não encaixa." % ram.ddr]
	for ddr in Hardware.DDR_TYPES:
		if _has(text, [ddr.to_lower()]):
			return "%s usa %s. %s" % [board.model, board.ddr, "Essa é a geração certa para a placa." if board.ddr == ddr else "%s não encaixa nessa placa." % ddr]
	return "%s usa soquete %s e memória %s em %d slots. Qual processador ou módulo vai entrar nela?" % [board.model, board.socket, board.ddr, board.slot_count]


static func _customer(ledger: RefCounted, order: Dictionary, topic: String, text: String) -> String:
	match topic:
		"price":
			return "Pelo combinado da ordem %s, o total é %s, com %s adiantados para as peças. Se tiver alguma dúvida sobre o valor, me avisa por aqui." % [order.id, Prefs.money(order.reward), Prefs.money(order.deposit)]
		"symptom", "memory", "compatibility":
			return "%s\n\nFoi isso que eu percebi usando a máquina. Quer que eu explique quando começou?" % order.report
		"system":
			return "Prefiro manter o que já está no meu disco. Se o sistema precisar ser reinstalado, me avisa antes para eu saber o que vai mudar."
		"deadline", "delivery", "progress":
			match order.status:
				"offered": return "Ainda estou esperando você receber a ordem %s no balcão. Posso combinar a entrega por lá." % order.id
				"declined": return "Vi que você recusou a ordem %s. Vou procurar outra assistência para essa máquina." % order.id
				"delivered": return "Já retirei o computador da ordem %s no balcão. Obrigado por acompanhar o serviço." % order.id
				"active":
					var pc: Dictionary = ledger.item(order.pc_id)
					if pc.get("boot_ok", false): return "Que bom que voltou a iniciar! Quando o serviço estiver concluído, passo no balcão para retirar."
					return "O computador da ordem %s já está com a oficina. Pode me avisar quando terminar de testar? Eu retiro no balcão." % order.id
		_:
			if _has(text, ["sim", "explique", "comecou", "aconteceu", "quando apareceu"]):
				return "Notei o problema durante o uso normal. Desde então acabou se repetindo, por isso resolvi levar para vocês testarem."
	return "Sobre a ordem %s, você precisa que eu explique o defeito, confirme o valor ou combine a retirada?" % order.id


static func _clara(topic: String, text: String) -> String:
	match topic:
		"price": return "Quero começar com algo que caiba no orçamento. Uso navegador, chamadas de vídeo e documentos. Qual seria sua sugestão pra esse uso?"
		"deadline", "delivery": return "Posso ir ao balcão durante o dia. Antes de marcar, queria decidir as peças do computador com você."
		"compatibility", "memory": return "Eu uso várias abas e uma chamada de vídeo ao mesmo tempo. Acha que 16 GB seria uma boa escolha pra começar?"
		"system": return "Posso usar o TechOS para navegador e documentos? Se der, é o que eu prefiro para essa máquina."
		_:
			if _has(text, ["jogo", "jogos", "estudar", "estudo", "trabalho"]): return "Também quero usar para estudar. Jogo de vez em quando, mas prefiro gastar pouco agora e deixar espaço para melhorar depois."
	return "Estou planejando meu computador de estudos. Se você me sugerir uma peça ou um valor, posso te dizer se faz sentido para mim."
