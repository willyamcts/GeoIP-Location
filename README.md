# Base para geolocalização / GeoIP

## Descrição
Cria base de dados com a estrutura de arquivos e diretórios descrita no tópico a seguir, cada arquivo `.zone` contém os blocos de endereços IP pertencentes a cada país.

A base de dados contendo os blocos alocados para cada país é diariamente atualizada e pode ser encontrada em [NRO](https://www.nro.net/about/rirs/statistics/)

Outra base separada por RIR's pode ser encontrada [aqui](https://ftp.lacnic.net/pub/stats/) 

## Estrutura de arquivos
Base de blocos alocados por país:

```
+ <DIR DEFINED IN SCRIPT>
            |-- ipv[4|6]
                  |-- <sigla>.zone 
```

Histórico de atualizações do arquivo:

```
+  <DIR DEFINED IN SCRIPT>
            |-- nro-delegated-stat-<CREATION TIME>
```
Cada download é armazenado com a data original de criação para evitar que haja armazenamento duplicado. A intenção de manter cópias é apenas para comparações futuras.


# Features futura
 - Mostrar a quantidade de endereços alocados por região
 - Associar com dados de TLD com quantidade de DNS registrados em cada
 - Docker metabase para apresentar as informações
