#version 330

uniform sampler2D MainSampler;

in vec2 texCoord;

out vec4 fragColor;

void main(){
	fragColor = texture(MainSampler, texCoord);
}
