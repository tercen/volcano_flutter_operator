# Volcano Flutter

## Description

This operator is written in flutter/dark to replace the ShinyR implementation located at [volcano_shiny](https://github.com/tercen/volcano_shiny)

## Usage

Input projection|.
---|---
`x-axis`        | log2 fold change (numeric)
`y-axis`        | negative log10 of the p-values adjusted for multiple testing (numeric)
`labels`        | the gene names to be displayed on the plot (character)

Output relations|.
---|---
`Operator view`        | view of the application

## Details

Volcano plots show the significance (typically negative log10 of the p-values adjusted for multiple testing, y-axis) against the change in gene expression (log2 fold change, x-axis). Additionally, the genes can be labelled using a gene name variable mapped onto 'labels'.

## See Also

[volcano_shiny](https://github.com/tercen/volcano_shiny) - Original ShinyR implementation

## Open Source Attribution

This operator is an implementation based on VolcaNoseR.

### About VolcaNoseR

The VolcaNoseR web app is a dedicated tool for exploring and plotting Volcano Plots. Users can explore the data with a pointer (cursor) to see information of individual datapoints. The threshold for the effect size (fold change) or significance can be dynamically adjusted. The plot can be annotated to show genes/proteins based on their top ranking or based on user input. More details about the VolcaNoseR app can be found in our publication

The plot can be saved as a PNG file or a PDF file, which can be opened and edited with Adobe Illustrator to allow for fine adjustments of the lay-out.

### Contact

VolcaNoseR is created and maintained by Joachim Goedhart and Martijn Luijsterburg
Bug reports and feature requests can be communicated in several ways:

Github: <https://github.com/JoachimGoedhart/VolcaNoseR/issues>
Twitter: @joachimgoedhart
Email: j.goedhart@uva.nl
