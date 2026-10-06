# ChileDex

![Estado: En desarrollo](https://img.shields.io/badge/Estado-En%20desarrollo-yellow)
![Plataforma: Mobile](https://img.shields.io/badge/Plataforma-iOS%20%7C%20Android-lightgrey)

## Descripción

**ChileDex** es una aplicación móvil propuesta como proyecto de título que funciona como una enciclopedia interactiva de la flora y fauna chilena. Inspirada en la mecánica de una "Pokédex", combina un catálogo educativo con un sistema de identificación visual mediante la cámara del dispositivo. 

**Objetivos principales:**
* Reducir la brecha de conocimiento ambiental en la población.
* Incentivar la actividad física al aire libre y combatir el sedentarismo.
* Promover el descubrimiento y la valoración del patrimonio natural de Chile mediante mecánicas de gamificación y logros.

## Arquitectura

El proyecto está diseñado bajo una arquitectura moderna cliente-servidor que integra modelos de inteligencia artificial:
Diagrama de arquitectura

## Tecnologías

El stack tecnológico inicial (sujeto a evolución durante el desarrollo) está compuesto por:

* **Frontend:** ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
* **Backend:** ![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white) ![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
* **Base de Datos:** ![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
*   **Inteligencia Artificial:** Modelo extraido de Hugging Face - BioCLIP-2

## Integrantes y Roles

Proyecto de título desarrollado por estudiantes de **Duoc UC** (Sede Antonio Varas):

### Integrantes y Roles

| Foto / Avatar | Nombre | Rol Principal |
| :---: | :--- | :--- |
| <img src="https://github.com/alovidal.png" width="50" style="border-radius:50%"> | **Alonso Vidal Moreno** | Roles compàrtidos |
| <img src="https://github.com/ignaciocorrea1.png" width="50" style="border-radius:50%"> | **Ignacio Correa Ramírez** | Roles compàrtidos |
| <img src="https://github.com/NarayaniGarcia.png" width="50" style="border-radius:50%"> | **Narayani García Chamorro** | Roles compàrtidos |

## Metodología y Estado

Trabajamos con Scrum, adaptado a un equipo de tres personas. El proyecto se organizó en siete sprints de dos semanas, desde mediados de agosto hasta fines de noviembre.

**¿Por qué Scrum?** La razón principal es que al empezar no podíamos especificar el proyecto completo. La parte más riesgosa, el reconocimiento de especies por cámara, dependía de cosas que solo se saben probando: si existían suficientes fotografías con licencia abierta, si catorce especies chilenas se distinguían bien entre sí, si nos servía un modelo ya entrenado o había que entrenar uno desde cero. Un método que exigiera cerrar el diseño en agosto nos habría obligado a comprometernos con decisiones que todavía no teníamos cómo evaluar.
Y de hecho fueron cambiando cosas en el camino. Descubrimos que no existe ningún conjunto de datos de flora y fauna chilena, que varios nombres científicos tenían sinónimos que había que resolver antes de descargar nada, y que algunas especies no tienen clasificación de conservación chilena, por lo que hay que mostrar la internacional indicando de dónde viene. Con un plan cerrado cada uno de esos hallazgos habría sido un problema. Con sprints fueron ajustes al backlog.
Lo segundo es la fecha. La presentación es en diciembre. Los sprints de dos semanas nos obligan a tener algo demostrable seguido, y así un atraso se nota en octubre y no en la última semana.

**¿Por qué no otras?** Un modelo en cascada no calzaba por lo mismo: pide requisitos estables y los nuestros no lo eran. Kanban nos servía para el flujo de trabajo, pero no tiene compromiso por período ni cortes fijos, y con una fecha de entrega cerrada preferimos una cadencia que nos obligue a medir el avance cada dos semanas. XP aporta buenas prácticas, pero pide programación en pareja y pruebas automatizadas que no podemos sostener trabajando en la práctica al mismo tiempo.

**Cómo lo aplicamos**
Siete sprints de dos semanas. El tercero duró tres semanas por el feriado de Fiestas Patrias.
No designamos Product Owner ni Scrum Master. Somos tres, todos conocemos el producto completo y las decisiones de prioridad y de proceso las tomamos en conjunto. Nombrar roles habría sido un formalismo.
Nos coordinamos una vez por semana en la clase de Capstone y por mensajería el resto del tiempo.
Al abrir cada sprint elegimos las historias, las partimos en tareas y estimamos las horas. Al cerrarlo revisamos lo hecho y qué conviene cambiar para el siguiente.
Los artefactos que mantenemos son el Product Backlog, un Sprint Backlog por sprint y la Definición de Terminado.


## Ejecucion Local

---
*Desarrollado para la asignatura Capstone - Docente: Rocio Contreras Aguila.*
