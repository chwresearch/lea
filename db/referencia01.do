/* 
referencia01.do

Referencia sobre preambulo de prepara.do
No usar save, replace sin consultar
*/

clear
set mem 200m
capture log close
log using "prepara.txt", replace
* asegurarnos que estamos en la carpeta /db
* cd "C:\...\data\db" Windows
* cd "/.../lea/do" Mac
* ===============================
* 2. Abrimos la base de personas (Caps. 1-11,16)
use "personas.dta"


* ================================================
* PREAMBULO
* ================================================

*generar ponderadores

gen pondera = destring(FACTOR)
label var pondera "factor de ponderación"

*Identificador de hogar
gen id_hogar =  NUMHOG
label var id_hogar "identificación única del hogar"

* Relación con jefe de familia
gen relacion = PPA05
label var relacion "Relación con el jefe del hogar"

* Creacion variable jefe del hogar
gen jefe = .
replace jefe = 1 if relacion == 1
replace jefe = 0 if relacion >= 2 & relacion <= 13
tab jefe, missing

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
*replace PEA = 1 if P10A02 == 1 | P10A02 == 2
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

* A.******************* INGRESOS LABORALES ***************************
* A.1. Ocupación PRINCIPAL
* A.1.1. Ingreso monetario ocupación principal
/*
/ P10B08  ¿Cuál fue el sueldo o salario mensual bruto antes de descuentos en éste trabajo?		*
/ P10B09C ¿Cuantó le pagan por hora extra trabajada?							*
/ P10B10b ¿Cuánto dinero recibió por concepto de comisiones o propinas?				*
/ P10B18b ¿Cuánto dinero le pagaron por trabajar en su periodo vacacional?				*
/ P10B22  ¿Cuál es su ingreso neto o ganancia mensual de su empresa, negocio o actividad, después de quitar los gastos?	*
 P10B23  ¿Cuál fue su ingreso neto o ganancia mensual por ventas de cosechas, animales o subproductos?			*
*/

egen ip_m = rsum(P10B08 P10B09C P10B10B P10B18B P10B22 P10B23)
replace ip_m = . if P10B08 == . & P10B09C == . & P10B10B == . & P10B18B == . & P10B22 == . & P10B23 == .
label var ip_m "ingreso monetario ocupación principal"

* A.1.2. Ingreso no monetario ocupación principal
* Asalariados
/*
* P10B13B ¿Cuánto dinero recibió por concepto de algún quinceavo sueldo o diferido? 		*
* P10B14B ¿Cuánto dinero recibió por concepto de bono vacacional?				*
* P10B15B ¿Cuánto dinero recibió por concepto de bonos de productividad, desempelo o estímulos laborales?			*
* P10B16B ¿Cuánto le costaría la ropa, uniformes u otras prendas de vestir (sin costo alguno)?					*
* P10B19B ¿Cuánto le costaría en total los alimentos, víveres o subsidios de alimentación que recibio sin costo alguno?	*
* P10B20B ¿Cuánto le costaría la vivienda que recibió sin costo alguno?							*
* P10B21B ¿Cuánto le costaría el transporte gratuito o dinero adicional para transportarse a su trabajo?			*
*/

egen ip_nm = rsum(P10B13B P10B14B P10B15B P10B16B P10B19B P10B20B P10B21B)
replace ip_nm =. if P10B13B == . & P10B14B == . & P10B15B == . & P10B16B == .& P10B19B == . & P10B20B == . & P10B21B == .
label var ip_nm "ingreso no monetario ocupación principal-asalariado"

* A.1.3. Ingreso total ocupación principal
egen ip = rsum(ip_m ip_nm)
replace ip = . if ip_m == . & ip_nm == .
label var ip "ingreso total ocupación principal"

* A.1.4. Relación laboral ocupación principal
/* P10B04  ¿En el trabajo al que dedicó más horas la semana pasada o la última semana que trabajó (....) es o era:		
 1 = Empleado del gobierno?					
 2 = Empleado privado?					
 3 = Jornalero o peón?					
 4 = Empleado doméstico?					
 5 = Trabajador por cuenta propia NO agrícola?		
 6 = Patrón empleador socio No agrícola?			
 7 = Trabajador por cuenta propia agrícola?			
 8 = Patrón empleador socio agrícola?				
 9 = Trabajador familiar sin pago?	
 */			
gen relab = .
replace relab = 1 if P10B04 == 6 | P10B04 == 8
replace relab = 2 if P10B04 >= 1 & P10B04 <= 4
replace relab = 3 if P10B04 == 5 | P10B04 == 7
replace relab = 4 if P10B04 == 9
replace relab = 5 if desocupado == 1
label var relab "relación laboral"
tab relab, m

/*
 Nueva codificación	1 = empleador (patrón)			2 = Empleado asalariado		
			3 = independiente (cuentapropista)	4 = Sin salario			
			5 = Desocupado								

 A.2. Ocupación secundaria
 A.2.1. Ingreso monetario ocupación secundaria
 P10C01 Además del trabajo principal, ¿Tuvo un segundo trabajo la semana pasado?		

 P10C04 ¿En éste segundo trabajo, usted es:							
 1 = Empleado del gobierno?					
 2 = Empleado privado?					
 3 = Jornalero o peón?					
 4 = Empleado doméstico?					
 5 = Trabajador por cuenta propia NO agrícola?		
 6 = Patrón empleador socio No agrícola?			
 7 = Trabajador por cuenta propia agrícola?			
 8 = Patrón empleador socio agrícola?				
 9 = Trabajador familiar sin pago?				

 P10C05  ¿Cuál fue su sueldo o salario mensual bruto antes de descuentos que recibió en éste segundo trabajo?	
 P10C06B El mes pasado, además del sueldo o salario, ¿Recibió comisiones, horas extras propinas, dietas o gastos de representación?	
 P10C09B Durante los últimos 12 meses ¿recibió bono 14, aguinaldo o bono vacacional en éste segundo trabajo?	
 P10C10B Durante los últimos 12 meses, ¿recibió dinero por concepto de algún quinceavo sueldo o diferido, bono de productividad o estimulos laborales en éste segundo trabajo?	
 P10C11  Normalmente ¿Cuál es su ingreso neto o ganancia mensual de su empresa, negocio, actividad o profesión, después de quitar los gastos?						
 P10C12  En los últimos 12 meses, ¿cuál fue su ganancia o ingreso promedio mensual por concepto de ventas de cosechas, animales yo ventas de subproductos?				
*/

egen is_m = rsum(P10C05 P10C06B P10C09B P10C10B P10C11 P10C12)
replace is_m = . if P10C05 == . & P10C06B == . & P10C09B == . & P10C10B == . & P10C11 == . & P10C12 == .
label var is_m "ingreso monetario ocupación secundaria"

/*
 A.2.2. Ingreso no monetario ocupación secundaria
 Asalariados
 P10C08B ¿recibió alimentos, vívers, ropa o calzdo como parte del pago por éste segundo trabajo?			
 P10C09B ¿recibió vivienda, transporte o subsidio de transporte como parte del pago por éste segundo trabajo?		
*/

egen is_nm = rsum(P10C08B P10C09B)
replace is_nm = . if P10C08B == . & P10C09B == .
label var is_nm "ingreso no monetario ocupación secundaria"

* A.2.3. Ingreso total ocupación secundaria
egen is = rsum(is_m is_nm)
replace is = . if is_m == . & is_nm == .

/*
 A.3. Otras ocupaciones
 A.3.1. Ingreso monetario otras ocupaciones
 Cuenta propia - ingreso agrícola
 P11A12B ¿Cuánto dinero recibió por concepto de ventas de cosechas o animales como: cerdos, gallinas, vacas u otros animales domésticos?				
*/

gen yagric= (P11B12B)/12
label var yagric "Ingresos mensuales act. agricolas"
gen yagric_12 = P11B12B
label var yagric_12 "Ingresos anualment act. agricolas"

/*
 A.3.2. Ingreso no monetario otras ocupaciones  No sirve la base de datos 
 P12A07  En los últimos 12 meses, ¿Usted o algún otro miembro del hogar, obtuvieron ... de la producción propia o lo obtuvieron sin tener que comprarlo?	
 P12A08  En los últimos 12 meses, ¿durante cuántos meses obtuvieron (...) sin tener que comprarlo?								
 P12A09D ¿Qué camtidad de (...) obtienen normalmente en un mes sin tener que comprarlo?									
 P12A10D En los últimos 15 días, ¿qué cantidad de (...) obtuvieron sin tener que comprarlo?									
 P12A11? ¿De dónde obtienen normalmente:   	A. Producción propia?	
						B. Regalo o donación?	
						C. Parte de un pago?	
						D. Del negocio?		
						E. Trueque		
		1 = Sí		2 = No		
*/			

* gen autocons1 = .
* replace autocons1 = 1 if P12A11A == 1 | P12A11B == 1 | P12A11C == 1 | P12A11D == 1 | P12A11E ==1
* replace autocons1 = 0 if P12A11A == 2 | P12A11B == 2 | P12A11C == 2 | P12A11D == 2 | P12A11E ==2
* egen autocons = rsum (P12Z09D P12A10D autocons1)
* drop autocons1

* A.3.3. Ingreso total otras ocupaciones
gen iotras = yagric
replace iotras = . if yagric == .

* A.4. Todas las ocupaciones
* A.4.1. Ingreso monetario todas las ocupaciones
egen ila_m = rsum (ip_m is_m yagric)
replace ila_m = . if ip_m == . & is_m == . & yagric == .
label var ila_m "ingreso laboral monetario"

* A.4.2. Ingreso no monetario todas las ocupaciones
egen ila_nm = rsum (ip_nm is_nm)
replace ila_nm = . if ip_nm == . & is_nm == .
label var ila_nm "ingreso laboral no monetario"

* A.4.3. Ingreso total todas las ocupaciones
egen ila = rsum (ila_m ila_nm)
replace ila = . if ila_m == . & ila_nm == .
label var ila "ingreso laboral total"

* IDENTIFICACIÓN PERCEPTORES INGRESOS LABORALES
gen perila = 0
replace perila = 1 if ila > 0 & ila != .
label var perila "1= si perceptor ingreso laboral"

* A.5. Ingresos laborales horarios
gen ilaho = ila / (hstrt*4)
label var ilaho "horario ingreso laboral"


* B. **************** Ingresos No Laborales ************************
* B.1. Ingreso monetario no laboral

/* Ayudas y otros trabajos no reportados
 Capital 			
 P11A01B ¿Cuánto dinero recibió por concepto de alquiler de habitaciones, viviendas, maquinaria, terrenos, etc.?				
 P11A02B ¿Cuánto dinero recibió por concepto de intereses?											
 P11A03B ¿Cuánto dinero recibió por concepto de dividendos or acciones?					

 Jubilaciones			
 P11A04B ¿Cuánto dinero recibió por concepto de jubilaciones o pensiones?					

 Transferencias		
 P11A05B ¿Cuánto dinero recibió por concepto de ayudas o donaciones de personas ubicadas en Guatemala?	
 P11A06B ¿Cuánto dinero recibió por concepto de remesas de personas que viven en el extranjero?		
 P11A07B ¿Cuánto dinero recibió por concepto de becas de estudio yo bonos por transporte escolar?		
 P11A08B ¿Cuánto dinero recibió por concepto de pensión alimenticia por divorcio o separación?		
 P11A09B ¿Cuánto dinero recibió por concepto de indemnizaciones de seguro de vida, accidentes o despido?	
 P11A10B ¿Cuánto dinero recibió por concepto de herencias, loterías o premios?				
 P11B11B ¿Cuánto dinero recibió por concepto de trabajos diferentes a los ya reportados?			
 P11B12B ¿Cuánto dinero recibió por concepto de ventas de cosechas o animales como cerdos, gallinas, vacas u otros animales domésticos?	
 P11B13B ¿Cuánto dinero recibió por concepto de negocios diferentes a los ya reportados?			
 P11B14B ¿Cuanto dinero recibió por concepto de otros ingresos además de los mensionados anteriormente?	
*/

* mensualizar valores
gen p11a01b2 = P11A01B/3
gen p11a02b2 = P11A02B/3
gen p11a03b2 = P11A03B/3
gen p11a04b2 = P11A04B/3
gen p11a05b2 = P11A05B/3
gen p11a06b2 = P11A06B/3
gen p11a07b2 = P11A07B/3
gen p11a08b2 = P11A08B/3
gen p11a09b2 = P11A09B/3
gen p11a10b2 = P11A10B/3
gen p11b11b2 = P11B11B/3
gen p11b12b2 = P11B12B/3
gen p11b13b2 = P11B13B/3
gen p11b14b2 = P11B14B/3

egen inla_m = rsum(p11a01b2 p11a02b2 p11a03b2 p11a04b2 p11a05b2 p11a06b2 p11a07b2 p11a08b2 p11a09b2 p11a10b2 p11b11b2 p11b12b2 p11b13b2 p11b14b2)
replace inla_m = . if P11A01B == . & P11A02B == . & P11A03B == . & P11A04B == . & P11A05B == . & P11A06B == . & P11A07B == . & P11A08B == . & P11A09B == . & P11A10B == . & P11B11B == . & P11B12B == . & P11B13B == . & P11B14B == .
label var inla_m "ingreso monetario no laboral"
drop p11a01b2 
drop p11a02b2 
drop p11a03b2
drop p11a04b2 
drop p11a05b2
drop p11a06b2
drop p11a07b2
drop p11a08b2
drop p11a09b2
drop p11a10b2
drop p11b11b2
drop p11b12b2
drop p11b13b2
drop p11b14b2

* Ingreso total no laboral
egen inla = rsum(inla_m)
replace inla = . if inla_m == .
label var inla "ingreso total no laboral"

* C.*********** Ingresos Totales *************************
* C.1. Ingreso monetario individual
egen ii_m  = rsum (ila_m inla_m)
replace ii_m = . if ila_m == . & inla_m == .
label var ii_m "ingreso individual monetario"

* C.2. Ingreso total individual
egen ii = rsum (ila inla)
replace ii = . if ila == . & inla == .
label var ii "ingreso individual"

* IDENTIFICA PERCEPTORES DE INGRESOS
gen perii = 0
replace perii = 1 if ii > 0 & ii ~= .
label var perii "=1 si perceptor ingreso"

* D. ********** Ingresos Familiares **************************
* Número de perceptores de ingresos laborales en un hogar
bysort id_hogar: egen n_perila_h = sum(perila) if hogarsec == 0
label var n_perila_h "número de percepctores ila en hogar"

* Número de perceptores de ingreso en un hogar
bysort id_hogar: egen n_perii_h = sum(perii) if hogarsec == 0
label var n_perii_h "número perceptores iii en hogar"

* Ingreso monetario total familiar
bysort id_hogar: egen itf_m = sum(ii_m) if hogarsec == 0
label var itf_m "ingreso monetario total familiar"

* Ingreso total familiar
bysort id_hogar: egen itf = sum(ii) if hogarsec == 0
label var itf "ingreso total familiar"
gen itf_12=itf*12
label var itf_12 "ingreso total familiar por anio"

* E. ********* Ingresos Familiares Ajustados por Factores Demograficos **************
* Ingreso monetario per cápita familiar
gen ipcf_m = itf_m/miembros
label var ipcf_m "ingreso monetario per capita familiar"

* Ingreso per cápita familiar
gen ipcf = itf/miembros
label var ipcf "ingreso per capita familiar"
gen ipcf_12=ipcf*12
label var ipcf_12 "ingreso per capita familiar por anio"
