Este repositorio forma parte del proyecto de fin de carrera de don Alejandro Tomás Martínez para el grado en ingeniería informática.

El proyecto consiste en desarrollar un videojuego para la consola GameBoy clásica. Para ello, deberemos aprender la arquitectura hardware que compone la consola, su set de instrucciones, el renderizado de píxeles y las peculiaridades de la consola.

También deberemos de aprender múltiples conceptos relacionados con la tecnología empleada, así como familiarizarnos con las propias herramientas que nos proporciona la suite de desarrollo RGBDS.

También va a ser necesario idear el videojuego a desarrollar cuando se controle la programación en la consola.





- El comienzo
    - [x] Conocer la estructura hardware de la consola.
    - [x] Familiarizarse (otra vez) con el lenguaje ensamblador y con el ISA de la consola.
    - [x] Comprender el funcionamiento del renderizado de píxeles.
    - [x] Codificación 2BPP y creación de tiles con RGBDS.
    - [x] Aprender el funcionamiento de los tiles, tilemaps y objects.
    - [x] Comprender el funcionamiento de inputs.
    - [x] Sistema de colisiones básico.
    - [x] Manejo de puntuaciones.
    - [x] Realizar el primer tutorial de gbdev: Un juego Arkanoid.

- La aventura continúa
    - [ ] Modificar el makefile a mi gusto.
    - [ ] Realizar el segundo tutorial de gbdev: Juego Shooter.
    - [ ] Renderizado avanzado de backgrounds.
    - [ ] Cinemáticas.
    - [ ] Cambios de escena.
    - [ ] Diálogos.

- El juego
- [ ] Juego tipo Isaac con mazmorras generadas proceduralmente / estilo mapa mundo abierto como minecraft.
- [ ] Elegir el estilo del juego.
- [ ] Obtener tiles del juego.


Pinceladas sobre la generación de terreno con ruido:
https://www.redblobgames.com/maps/terrain-from-noise/

1. Crear una función de generación de ruido -> perlin -> simplex es su evolución y requiere menos multiplicaciones, puede ser interesante de cara a las limitaciones técnicas de la consola.

1. Generar un heightmap

2. Generar un mapa de árboles/piedras. -> Esto sinceramente pueden ser puntos aleatorios en los que se genera un árbol con x probabilidad si no hay otro arbol en un radio Y. -> Puede usarse perlin noise, pero hay métodos más eficientes. Hay que abordar el problema de si la forma del árbol va a ser aleatoria o fija, y cómo calcular las hojas con una función para no tener que almacenarlo en ram.

Lo que si es destacable es la posibilidad de hacer que el tile de las hojas pueda superponerse al personaje, pero que siga habiendo colisiones en el caso
de que las hojas tapen una diferencia de altura, por ejemplo. -> Dos tiles para el mismo sprite de hoja, pero que uno bloquee el movimiento y el otro no, y al general el arbol usamos el que bloquea si antes había un tile que bloquea y viceversa.

3. Mapa con rios? -> A partir de cierta altura generar agua y arena si eso y ya.

4. Mirar lo del subtile movement del zelda.

5. Optimizar la generación del mapa -> Generar todo el mapa de una y guardarlo en la memoria ram (ya que en la rom no se puede) parece algo impensable o limitado a un mapa pequeño. La alternativa que se me ocurre es 
que conforme se mueva el personaje, se genere el mapa en dicha dirección, en base a una funcion noise(x,y) para la altura, árboles, agua... -> El orden de dicha generación es importante ya que podríamos ahorrarnos tiempo de cálculo (si el agua la calculamos en base a si altura < x entonces podemos ahorrarnos comprobar si ahí va un árbol...).



 