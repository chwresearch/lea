/* 
referencia01.do

Referencia sobre preambulo de prepara.do

*/

clear
set mem 200m
capture log close
log using "prepara.txt", replace
* asegurarnos que estamos en la carpeta /db
* cd "C:\...\lea\db" Windows
* cd "/.../lea/do" Mac
* ===============================
* 2. Abrimos la base de personas (Caps. 1-11,16)
use "C:/data/db-original/02_enc11_personas.dta"


* ================================================
* PREAMBULO
* ================================================

*generar ponderadores

gen pondera = factor
label var pondera "factor de ponderación"

*Identificador de hogar
gen id_hogar =  formulario
label var id_hogar "identificación única del hogar"

* Relación con jefe de familia
gen relacion = PPA05
label var relacion "Relación con el jefe del hogar"

* Creacion variable jefe del hogar
gen jefe = .
replace jefe = 1 if relacion == 1
replace jefe = 0 if relacion >= 2 & relacion <= 13
tab jefe, m

* Hogares secundarios
gen hogarsec = 0
replace hogarsec = 1 if relacion >= 11 & relacion <= 13

* Variable auxiliar para contabilizar miembros de hogar primario
gen aux = 1

* Número de personas en el hogar primario
bysort id_hogar: egen miembros = sum(aux) if hogarsec == 0
label var miembros "Miembros del hogar principal"

drop aux

tab miembros, m

* Edad 
gen edad = PPA03
label var edad "edad"

* Sexo
* dummy de hombre
gen hombre = .
replace hombre = 0 if PPA02 == 2
replace hombre = 1 if PPA02 == 1
label var hombre "Dummy = 1 si hombre"
tab hombre, m

* Asiste a la educación formal
gen asiste = .
replace asiste = 0 if P06B22 != 1
replace asiste = 1 if P06B22 == 1
label var asiste "= 1 si asiste"

* Nivel educativo 
gen nivel = .
replace nivel = 0 if P06B25A>=1 & P06B25A<=2

replace nivel = 1 if P06B25A==3 & P06B25B<6

replace nivel = 2 if P06B25A==3 & P06B25B==6 & asiste==0

replace nivel = 3 if P06B25A==3 & P06B25B==6 & asiste==1
replace nivel = 3 if P06B25A==4
replace nivel = 3 if P06B25A==5 & P06B25B<3

replace nivel = 4 if P06B25A==5 & P06B25B==3 & asiste==0

replace nivel = 5 if P06B25A==5 & P06B25B==3 & asiste==1
replace nivel = 5 if P06B25A==6 & P06B25B<4
replace nivel = 5 if P06B25A==6 & P06B25B>=4 & P06B25B<=6 & asiste ==1

replace nivel = 6 if P06B25A==6 & P06B25B>=4 & P06B25B<=6 & asiste ==0
replace nivel = 6 if P06B25B==7
label var nivel "nivel educativo"

* Urbano y rural
gen urbano = .
replace urbano = 1 if area == 1
replace urbano = 0 if area == 2
label var urbano "= 1 es urbano"

* Fuerza laboral o población económicamente activa
* PEA = 1 si es parte de la PEA
/* P10A02 ¿Cuál fue la actividad pruincipal de (...) la semana pasada? para personas de 7 años y más	
	1 = Trabajar		2 = Buscar trabajo								
	3 = Estudiar		4 = Que haceres del hogar							
	5 = Incapacitado	6 = Jubilado o pensionado							
	7 = Rentista		8 = Enfermo/convaleciente						
	98 = Otro												
 P10A03 Además de la actividad principal ¿La semana pasada... Trabajó al menos una hora por un sueldo o salario?. Trabajó como patrono o por su cuenta?, Vendió algún producto?, Recibió pago por lavar o planchar ropa ajena, cuidar carros, etc.?, Cultivó la tierra o crió animales?, Trabajó en un negocio familiar sin recibir pago?
 P10A04 Aunque ya me indicó que (...), no trabajó la semana pasada, ¿tenía algún empleo, negocio, actividad agrícola, fábrica o comercio por el que recibe ingresos o paga?																					
 P10C01 Además del trabajo principal de la semana pasada, ¿tenía un segundo trabajo, negocio o empresa?
 P10A07 En las últimas cuatro semanas ¿Hizo algún trámite para buscar trabajo o instalar su propio negocio?	
	1 = Si													
	2 = No													
P10D05 ¿Buscó trabajo por primera vez o había trabajado antes por lo menos durante dos semanas seguidas?
	1 = Buscó trabajo por primer vez									
	2 = Trabajó antes			*/								

gen PEA = .
replace PEA = 1 if P10A02 == 1 & P10A02 == 2
replace PEA = 1 if P10A03 == 1 & P10A03 != .
replace PEA = 1 if P10A04 == 1 & P10A04 != .
replace PEA = 1 if P10C01 == 1 & P10C01 != .
replace PEA = 1 if P10A07 == 1 & P10A07 != .
replace PEA = 1 if P10D05 <= 2

replace PEA = 0 if P10A02 > 2 & P10A02 != .
replace PEA = 0 if P10A03 == 2
replace PEA = 0 if P10A04 == 2
replace PEA = 0 if P10C01 == 2
replace PEA = 0 if P10A07 == 2
label var PEA "1= si activo"
tab PEA, m

* Ocupados
gen ocupado = .
replace ocupado = 1 if (P10A02 == 1 | P10A03 == 1 | P10A04 == 1 | P10C01 == 1)
replace ocupado = 0 if (P10A02 != 1 & P10A02 != . | P10A03 == 2 | P10A04 == 2 | P10C01 == 2) | P10A07 == 1 | P10D05 == 1
label var ocupado "= 1 si ocupado"

* Desocupados
gen desocupado = .
replace desocupado = 1 if P10A07 <= 2 & P10A07 != . | P10D05 == 1
replace desocupado = 0 if P10D05 == 2 | ocupado == 1
label var desocupado "=1 si desocupado"

* Horas trabajadas
* Horas trabajadas en la ocupación principal
/* P10B27A En éste trabajo ¿Cuántas horas trabaja normalmente cada uno de los siguientes días... lunes?
	P10B27B = martes? 	
	P10B27C = miércoles? 	
	P10B27D = jueves? 	
	P10B27E = viernes? 	
	P10B27F = sábado? 	
	P10B27G = domingo?	*/
egen htrp = rsum(P10B27A P10B27B P10B27D P10B27E P10B27F P10B27G)
replace htrp = . if P10B27A == . & P10B27B == . & P10B27C == . & P10B27D == . & P10B27E == . & P10B27F == . & P10B27G == .
replace htrp = 140 if htrp > 140 & htrp < .
label var htrp "horas trabajadas en la ocupación principal"

* Horas trabajadas todas las ocupaciones
/* P10C01 Además del trabajo principal de la semana pasada, ¿tenía un segundo trabajo, negocio o empresa?	
	1 = Si												
	2 = No												
P10C15 ¿Cuántas horas a la semana trabaja normalmente?	*/				
gen tmp = P10C15
replace tmp = htrp if tmp > htrp & tmp < .

egen hstrt = rsum(htrp tmp)
replace hstrt = . if (P10B27A == . & P10B27B == . & P10B27C == . & P10B27D == . & P10B27E == . & P10B27F == . & P10B27G == . & P10C15 == .)
replace hstrt = 140 if hstrt > 140 & hstrt < .
label var hstrt "horas trabajadas todas las ocupaciones"
drop tmp
