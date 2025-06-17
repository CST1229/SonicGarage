local font = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz:;.,'\"/()[\\]{|}=-+!?";
for i = 1, #font do
	local character = string.sub(font, i, i);
	app.sprite.layers[1]:cel(i).data = character;
end