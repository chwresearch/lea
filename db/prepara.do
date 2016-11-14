/* 
prepara.do
Ordena, limpia y prepara ENCOVI 2014
Crea un sistema de informacion Leer y Aprender

Programa Leer y Aprender

Determinacion del peso de variables que explican que los jovenes
no esten en la escuela, utilizando ENCOVI 2014 y priorizando barreras
identificadas por el proyecto Leer y Aprender del proyecto USAID /
Reforma Educativa en el Aula

*/

clear
set mem 200m
capture log close
log using "prepara.txt", replace
* asegurarnos que estamos en la carpeta /db
* cd "C:\...\lea\db" Windows
* cd "/.../lea/do" Mac

