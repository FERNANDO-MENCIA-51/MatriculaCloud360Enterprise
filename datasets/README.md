# Datasets

![Data Files](https://img.shields.io/badge/Datasets-Catalogo%20y%20Diccionario-0F766E)
![Excel](https://img.shields.io/badge/Excel-CatalogoDatos.xlsx-217346?logo=microsoftexcel&logoColor=white)
![PDF](https://img.shields.io/badge/PDF-DiccionarioDatos.pdf-B30B00?logo=adobeacrobatreader&logoColor=white)

## 1. 📌 Propósito de la carpeta

La carpeta `datasets/` centraliza la documentación y los insumos de referencia que soportan el modelo de datos del proyecto `MatriculaCloud360Enterprise`. Su función es servir como capa de apoyo entre el análisis funcional y la implementación física en SQL Server, asegurando que los datos maestros, las reglas de negocio y la definición técnica de los campos permanezcan alineados.

Esta capa es importante porque facilita la trazabilidad entre el negocio y la base de datos, reduce ambigüedades en la interpretación de los datos y ayuda a mantener consistencia en la estructura relacional del sistema de matrícula.

## 2. 📄 Descripción de los archivos

### 📘 `CatalogoDatos.xlsx`

Archivo de Excel que contiene el catálogo maestro de datos estructurados para el sistema de matrícula. Este recurso consolida valores de referencia, catálogos operativos y definiciones base que sirven como guía para poblar y validar la información en la base de datos.

Uso principal:

- Establecer valores maestros y listas controladas.
- Apoyar la carga inicial de datos y la validación de registros.
- Mantener consistencia entre el análisis funcional y los datos persistidos en SQL Server.

### 📗 `DiccionarioDatos.pdf`

Documento técnico en formato PDF que describe las definiciones de las tablas, los campos, los tipos de datos, las restricciones y los metadatos del modelo.

Uso principal:

- Documentar la estructura lógica y física de la base de datos.
- Precisar llaves primarias, foráneas y restricciones de negocio.
- Servir como referencia técnica para desarrolladores, analistas y responsables de datos.

## 3. 🧩 Relación con SQL Server

Estos documentos complementan directamente la base de datos SQL Server del proyecto:

- `CatalogoDatos.xlsx` apoya la estandarización de valores de referencia y el control de datos semilla.
- `DiccionarioDatos.pdf` respalda la definición del esquema relacional y la interpretación de cada entidad del modelo.

Juntos permiten que la implementación en SQL Server mantenga coherencia con las reglas del negocio, la nomenclatura de los campos y la integridad de los datos.

## 4. ✅ Uso recomendado

Se recomienda consultar estos archivos antes de crear, modificar o validar objetos de base de datos, especialmente durante el diseño de tablas, la carga inicial de información y la revisión de reglas de negocio.

Orden sugerido de consulta:

1. Revisar `DiccionarioDatos.pdf` para entender la estructura, relaciones y restricciones.
2. Consultar `CatalogoDatos.xlsx` para validar catálogos, valores permitidos y datos de referencia.
3. Comparar ambos recursos con los scripts DDL y DML del proyecto para asegurar consistencia total.

Este enfoque ayuda a mantener un modelo de datos ordenado, documentado y alineado con la arquitectura académica del sistema.

