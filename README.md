# 🔧 Sistema de Control de Temperatura con Activación de Ventilación

Proyecto integrador desarrollado en la asignatura **Electrónica Digital II**, que implementa un sistema embebido basado en el microcontrolador **PIC16F887** para monitorear la temperatura ambiente y activar automáticamente un ventilador de refrigeración cuando se supera un umbral definido.

---

## 🎯 Funcionalidades principales

- Lectura de temperatura ambiente con **sensor LM35**
- Activación automática de **cooler** si la temperatura supera los **26 °C**
- Encendido de **LEDs** indicadores del estado del sistema
- Control de encendido/apagado mediante **teclado matricial 3x3** con código de acceso
- Visualización de código ingresado en **3 displays de 7 segmentos**
- Transmisión de temperatura en tiempo real vía **comunicación serial (USART)** a una PC

---

## ⚙️ Tecnologías y componentes

- 🧠 **Microcontrolador:** PIC16F887
- 🌡️ **Sensor de temperatura:** LM35
- 💡 **Señalización óptica:** LEDs rojo y verde
- 🧊 **Actuador:** Ventilador tipo cooler controlado con transistor 2N2222
- 🔢 **Visualización:** Displays de 7 segmentos (x3)
- 🎛️ **Entrada:** Teclado matricial 3x3
- 🔌 **Comunicación:** USB-UART con PL2303HX

---

## 🧪 Pruebas realizadas

- ✅ Activación y desactivación del sistema mediante código
- ✅ Control de ventilador ante temperaturas reales
- ✅ Comunicación exitosa por USART con terminal
- ✅ Visualización correcta en displays con multiplexado dinámico
- ⚠️ Observación: En 10% de los casos, los displays no inicializan correctamente tras reset manual



