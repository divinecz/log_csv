Log CSV
=======

Skript Log CSV slouží pro zpracování SD logů zařízení a jejich transformaci do konfigurovalného CSV výstupu.

Požadavky
---------
* **Ruby** 1.8.7 nebo 1.9.x (Ruby 1.8.6 a starší nelze použít) a **RubyGems**
   * Instalace pro Linux s APT (Ubuntu, Debian):

			apt-get install ruby rubygems

   * Instalace pro Wíndows: [http://rubyinstaller.org/](http://rubyinstaller.org/)

* Gem **Log Parser** v požadované verzi:

		gem install log_parser-X.X.X.gem
	
Použití
-------

Spuštění skriptu:

	./log_csv.rb PATH [options]

* `PATH` cesta k adresáři s log soubory. Logy musí být umístěny na přímé úrovni tohoto adresáře a musí mít příponu `*.log`.
* `[options]` volitelné parametry pro budoucí použití. Seznam všech parametrů se zobrazí pomocí parametru `-h`.

Po spuštění budou vytvořeny CSV soubory v adresáři `PATH` se stejným názvem jako původní `*.log` soubory, ale s příponou `*.csv`.

Konfigurace definic SD logů
---------------------------

Pro konfiguraci definic SD logů je určen soubor `sd_logs.yml` v adresáři se skriptem ve formátu [YAML](http://www.yaml.org/).

Jednotlivé logy jsou definovány v sekci `logs` s následnou sekcí logu označenou jeho identifikátorem, např.
`0x0100` kde `01` značí identifikátor typu logu a `00` identifikátor zařízení.

Hodnota `name` slouží k označení názvu logu a musí by být unikátní v rámci zařízení.
Vzhledem k budoucí kompatibilitě a opakované použitelnosti definic logů, by se mělo jednat o anglické názvy pouze s malými písmeny
bez mezer a speciálních znaků krom `_`, které by navíc měly být unikátní napříč všemi zařízeními.
Hodnota se pak také dále vyžívá v CSV výstupu.

Hodnota `size` určuje délku logu v bytech. U SD logu vždy `512`.

Sekce `attributes` slouží k definici jednotlivých atributů logu.
Následné sekce jsou označeny názvem atributu, která se také dále vyžívá v CSV výstupu.

V sekci atributu poté hodnota `read` označuje pozice dat atributu. Celá čísla označují pozice bytu od 0.
Desetinná část pak pozice bitu 0-7. Je také možné uvádět pozice jako rozsah bytů i bitů pomocí pomlčky, ale vždy jen jedním způsobem.
Tedy pouze např. `"1-9"` nebo `"1.0-9.7"`.
Jednotlivé části výrazu jsou oddělené čárkou.
Z důvodu kompatibility by měly být pozice uzavřeny v uvozovkách.

Hodnota `type` v sekci atributu určuje datový typ. V současné době je možné definovat tyto:

* `bcd` (Binary Coded Decimal) je číslo, kde číslici určují vzdy 4 bity
* `bool` hodnota true/false, kde true pokud je hodnota > 0
* `hex` kladné celé číslo jako hexadecimální řetězec
* `string` řetězec CP1250
* `uint` kladné celé číslo

Pro definici opakujících se částí lze využít YAML alias viz dokumentace YAML. V následující ukázce je využit alias `common_attributes`.
Všechny zde uvedené sekce a hodnoty jsou povinné. Ostatní sekce konfiguračního souboru jsou ignorovány.

Ukázka:

	logs:
	  0x0100:
	    name: operation_1
	    size: 512
	    attributes:
	      name:
	        read: "0-15,16"
	        type: string
	      online:
	      	read: "16.1"
	      	type: bool
	  0x0200:
	    name: operation_2
	    size: 512
	    attributes:
	      <<: *common_attributes
	common_attributes: &common_attributes
      name:
        read: "0-15"
        type: string

Konfigurace CSV výstupu
-----------------------

Pro konfiguraci CSV výstupu je určen soubor `csv.yml` v adresáři se skriptem ve formátu [YAML](http://www.yaml.org/).

Jednotlivé sloupce výstupu jsou definovány v sekci `columns` v pořadí, v jakém se mají exportovat.

Názvy sloupců odpovídají názvům atributů z definice logů.
Speciálním názvem sloupce `log_name` dojde k vložení názvu logu z jeho definice.
V případě, že analyzovaný log neobsahuje atribut se zadaným názvem, bude buňka výstupu ponechána prázdná.

Ukázka:

	columns:
	  - log_name
	  - time_hours
	  - time_minutes
	  - time_seconds
	  - name
	  - id

Pro atributy jejichž hodnotu je třeba před výstupem do CSV souboru nejdříve přeložit je určena slovníková sekce `dictionaries`.
Každý její záznam, který názvem odpovídá některému z atributů, obsahuje páry hodnot sloužící k překladu ve tvaru hodnota atributu a hodnota výstupu.
Pokud není v sekci nalezena žádná odpovídající hodnota pro překlad, bude ve výstupu uvedena nepřeložená původní hodnota.
V následující ukázce tedy pro atribut id bude pro hodnotu `0` a `1` použit ve výstupu překlad `on` a `off`.

Ukázka:

	dictionaries:
	  id:
	    0: off
	    1: on

Ostatní sekce konfiguračního souboru jsou ignorovány.