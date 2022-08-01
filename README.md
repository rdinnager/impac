
<!-- README.md is generated from README.Rmd. Please edit that file -->

# impac

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/impac/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/impac/actions)
<!-- badges: end -->

The goal of `{impac}` is to create packed image mosaics. The main
function `impac`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast\!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/impac")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(impac)
library(Rvcg)
library(rgl)
library(rphylopic)
```

Next we create an R function to generate an image. In this case, we use
the package `rgl` to plot a simple 3d shape, chosen randomly from a set
of possibilities:

``` r

generate_platonic <- function(i, swidth = 200, sheight = 200, cols = rainbow(100)) {
  
  shape <- sample(c("sphere",
                    "spherical_cap",
                    "tetrahedron",
                    "dodecahedron",
                    "octahedron",
                    "icosahedron",
                    "hexahedron",
                    "cube",
                    "cone"),
                  1)
  
  mesh <- switch (shape,
    sphere = Rvcg::vcgSphere(),
    spherical_cap = Rvcg::vcgSphericalCap(),
    tetrahedron = Rvcg::vcgTetrahedron(),
    dodecahedron = Rvcg::vcgDodecahedron(),
    octahedron = Rvcg::vcgOctahedron(),
    icosahedron = Rvcg::vcgIcosahedron(),
    hexahedron = Rvcg::vcgHexahedron(),
    cube = Rvcg::vcgBox(),
    cone = Rvcg::vcgCone(2, 0, 6)
  )
  
  scales <- c(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4)
  mesh <- rgl::scale3d(mesh, 
                       sample(scales, 1),
                       sample(scales, 1),
                       sample(scales, 1))
  
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 0, 1)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 1, 0)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 1, 0, 0)
  
  rgl::shade3d(mesh, col = sample(cols, 1),
               specular = "grey")
  
  png_file <- tempfile(fileext = ".png")
  rgl::snapshot3d(filename = png_file, width = swidth, height = sheight,
                  webshot = FALSE)
  rgl::close3d()
  
  im2 <- imager::load.image(png_file)
  im <- imager::imfill(swidth, sheight, val = c(0, 0, 0, 1))
  im[ , , , 1:3] <- im2 
  im[imager::R(im) == 1 & imager::G(im) == 1 & imager::B(im) == 1] <- 0
  
  im  
 
}
```

Now we feed our function to the `impac()` function, which packs the
generated images onto a canvas:

``` r
shapes <- impac(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images\! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::image_list(1, 10000)
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::image_data(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp$uid, c(2, 1, 3))
  dims <- dim(rot)
  im <- imager::as.cimg(as.vector(rot), dim = c(dims[1], dims[2], 1, dims[3]))
  max_dim <- which.max(dims[1:2])
  other_dim <- (max_size / dims[max_dim]) * dims[1:2][-max_dim]
  new_size <- c(0, 0)
  new_size[max_dim] <- max_size
  new_size[-max_dim] <- other_dim
  im <- imager::resize(im, new_size[1], new_size[2], interpolation_type = 6)
  im <- imager::imchange(im, ~ . < 0, ~ 0)
  im <- imager::imchange(im, ~ . > 1, ~ 1)
  ## this adds custom metadata
  list(im, uuid = uuid)
}
```

Now we run `impac` on our phylopic generating function:

``` r
phylopics <- impac(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(2); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Arthur S. Brum, Chuanixn Yu, Maija Karala, Dean Schnabel, Gareth Monger,
Pedro de Siracusa, Markus A. Grohme, Alexander Schmidt-Lebuhn, Chase
Brownstein, Stuart Humphries, Gopal Murali, Kamil S. Jaron, Margot
Michaud, Matt Crook, Gabriela Palomo-Munoz, Chris huh, S.Martini,
Zimices, Michelle Site, Caleb M. Brown, Carlos Cano-Barbacil, Javier
Luque, Julio Garza, Andrew A. Farke, Alexandre Vong, Rebecca Groom,
CNZdenek, John Conway, Steven Traver, Alexis Simon, Andrés Sánchez,
Maxime Dahirel, Emma Kissling, Gabriele Midolo, Emily Willoughby, Conty
(vectorized by T. Michael Keesey), Scott Hartman, Jose Carlos
Arenas-Monroy, Collin Gross, Griensteidl and T. Michael Keesey, Curtis
Clark and T. Michael Keesey, B. Duygu Özpolat, Sarah Werning, Tasman
Dixon, Jagged Fang Designs, Inessa Voet, Bruno C. Vellutini, Smokeybjb,
Ignacio Contreras, Steven Blackwood, Andrew Farke and Joseph Sertich,
Matt Martyniuk (modified by Serenchia), Nobu Tamura (vectorized by T.
Michael Keesey), Tracy A. Heath, Ferran Sayol, Birgit Lang, Unknown
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, T. Michael Keesey (after Ponomarenko), M Kolmann, Armin Reindl,
Andy Wilson, Xavier Giroux-Bougard, Andreas Trepte (vectorized by T.
Michael Keesey), Maxwell Lefroy (vectorized by T. Michael Keesey), Lukas
Panzarin (vectorized by T. Michael Keesey), Ville Koistinen and T.
Michael Keesey, Lukasiniho, T. Michael Keesey, Sean McCann, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Mali’o Kodis, photograph by
Hans Hillewaert, Melissa Broussard, Hans Hillewaert (vectorized by T.
Michael Keesey), Scott Hartman, modified by T. Michael Keesey, Alex
Slavenko, Lukas Panzarin, Ghedo (vectorized by T. Michael Keesey),
Jakovche, T. Michael Keesey (photo by Bc999 \[Black crow\]), Wayne
Decatur, T. Michael Keesey (after Kukalová), Michael Scroggie, Milton
Tan, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), David Liao,
Francesco “Architetto” Rollandin, Felix Vaux, Mo Hassan, Noah
Schlottman, photo by Martin V. Sørensen, Robbie Cada (vectorized by T.
Michael Keesey), François Michonneau, Joanna Wolfe, Noah Schlottman, Jan
A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), wsnaccad, Hugo Gruson, Tommaso
Cancellario, Michele M Tobias from an image By Dcrjsr - Own work, CC BY
3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>, Michael
Day, Kai R. Caspar, Ludwik Gąsiorowski, Christoph Schomburg, Todd
Marshall, vectorized by Zimices, Nancy Wyman (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Beth Reinke, Fcb981
(vectorized by T. Michael Keesey), Agnello Picorelli, Shyamal, Darius
Nau, Jerry Oldenettel (vectorized by T. Michael Keesey), Chris Jennings
(Risiatto), Anthony Caravaggi, Sharon Wegner-Larsen, Jimmy Bernot, James
R. Spotila and Ray Chatterji, (after Spotila 2004), FJDegrange, Cesar
Julian, Matt Martyniuk (vectorized by T. Michael Keesey), Melissa
Ingala, Daniel Jaron, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Martin R. Smith,
Jiekun He, Yan Wong, Chris A. Hamilton, Ryan Cupo, Noah Schlottman,
photo by Casey Dunn, Jack Mayer Wood, FunkMonk, Original drawing by
Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Skye McDavid,
Roberto Díaz Sibaja, Acrocynus (vectorized by T. Michael Keesey), Tony
Ayling (vectorized by Milton Tan), Noah Schlottman, photo by Museum of
Geology, University of Tartu, Yan Wong from photo by Gyik Toma, Richard
Ruggiero, vectorized by Zimices, Mason McNair, Steven Coombs (vectorized
by T. Michael Keesey), Geoff Shaw, Karla Martinez, Tyler Greenfield,
Lankester Edwin Ray (vectorized by T. Michael Keesey), Obsidian Soul
(vectorized by T. Michael Keesey), . Original drawing by M. Antón,
published in Montoya and Morales 1984. Vectorized by O. Sanisidro, C.
Camilo Julián-Caballero, NOAA (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Adam G. Clause, Farelli (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Tauana J. Cunha, Henry
Lydecker, Skye M, Ghedoghedo (vectorized by T. Michael Keesey), Ben
Liebeskind, Philippe Janvier (vectorized by T. Michael Keesey), Aviceda
(photo) & T. Michael Keesey, Mali’o Kodis, photograph by G. Giribet, M.
Garfield & K. Anderson (modified by T. Michael Keesey), C. W. Nash
(illustration) and Timothy J. Bartley (silhouette), \[unknown\],
Sebastian Stabinger, Darren Naish (vectorize by T. Michael Keesey),
Prathyush Thomas, Sergio A. Muñoz-Gómez, Cristopher Silva, Michael P.
Taylor, Mercedes Yrayzoz (vectorized by T. Michael Keesey), Stemonitis
(photography) and T. Michael Keesey (vectorization), Martin R. Smith,
from photo by Jürgen Schoner, (after McCulloch 1908), James I. Kirkland,
Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), David Sim (photograph) and T.
Michael Keesey (vectorization), Pranav Iyer (grey ideas), Robbie N. Cada
(vectorized by T. Michael Keesey), Ville-Veikko Sinkkonen, Erika
Schumacher, Kailah Thorn & Ben King, Oliver Voigt, xgirouxb, Joseph J.
W. Sertich, Mark A. Loewen, Óscar San−Isidro (vectorized by T. Michael
Keesey), ArtFavor & annaleeblysse, Samanta Orellana, Nobu Tamura
(modified by T. Michael Keesey), Nobu Tamura (vectorized by A.
Verrière), Terpsichores, Scott Reid, Ieuan Jones, Dmitry Bogdanov, Neil
Kelley, Zimices / Julián Bayona, Ray Simpson (vectorized by T. Michael
Keesey), Michael Ströck (vectorized by T. Michael Keesey), Jon Hill
(Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Mike
Hanson, T. Michael Keesey (after Heinrich Harder), Esme Ashe-Jepson, L.
Shyamal, JJ Harrison (vectorized by T. Michael Keesey), Oscar Sanisidro,
Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Tambja (vectorized by T. Michael Keesey), Mattia
Menchetti, Mathieu Pélissié, George Edward Lodge (modified by T. Michael
Keesey), Didier Descouens (vectorized by T. Michael Keesey), Abraão B.
Leite, Christine Axon, Ricardo N. Martinez & Oscar A. Alcober, Jan
Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Karl Ragnar Gjertsen (vectorized by T. Michael Keesey),
Francesca Belem Lopes Palmeira, Stephen O’Connor (vectorized by T.
Michael Keesey), Steven Coombs, T. Michael Keesey (after A. Y.
Ivantsov), Kent Elson Sorgon, Kanchi Nanjo, Owen Jones (derived from a
CC-BY 2.0 photograph by Paulo B. Chaves), Iain Reid, Matt Martyniuk,
Bennet McComish, photo by Avenue, Manabu Bessho-Uehara, Javier Luque &
Sarah Gerken, Ingo Braasch, Becky Barnes, Tod Robbins, Rafael Maia, Caio
Bernardes, vectorized by Zimices, Mali’o Kodis, photograph by P. Funch
and R.M. Kristensen, Armelle Ansart (photograph), Maxime Dahirel
(digitisation), Haplochromis (vectorized by T. Michael Keesey), Lee
Harding (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Gordon E. Robertson, Mathilde Cordellier, NASA, Chris
Jennings (vectorized by A. Verrière), Mali’o Kodis, photograph by Jim
Vargo, Notafly (vectorized by T. Michael Keesey), Noah Schlottman, photo
from Casey Dunn, T. Michael Keesey (vectorization) and Nadiatalent
(photography), G. M. Woodward, , E. J. Van Nieukerken, A. Laštůvka, and
Z. Laštůvka (vectorized by T. Michael Keesey), Jessica Rick, Mali’o
Kodis, image from the Smithsonian Institution, Mathew Wedel, Liftarn, I.
Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey), Nobu Tamura,
vectorized by Zimices, Bryan Carstens, Dianne Bray / Museum Victoria
(vectorized by T. Michael Keesey), Roberto Diaz Sibaja, based on Domser,
Christopher Laumer (vectorized by T. Michael Keesey), Mateus Zica
(modified by T. Michael Keesey), Nobu Tamura, ДиБгд (vectorized by T.
Michael Keesey), Nicolas Mongiardino Koch

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    540.327672 |    448.798619 | Arthur S. Brum                                                                                                                                                        |
|   2 |    106.296848 |    162.437770 | Chuanixn Yu                                                                                                                                                           |
|   3 |    540.171487 |     99.570518 | Maija Karala                                                                                                                                                          |
|   4 |    186.911875 |    375.366280 | Dean Schnabel                                                                                                                                                         |
|   5 |    385.268766 |    201.015081 | Gareth Monger                                                                                                                                                         |
|   6 |    812.212841 |    647.337694 | Pedro de Siracusa                                                                                                                                                     |
|   7 |    774.878226 |    122.088339 | Markus A. Grohme                                                                                                                                                      |
|   8 |    257.860165 |    270.018061 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|   9 |    504.837349 |    551.776095 | Chase Brownstein                                                                                                                                                      |
|  10 |    399.547021 |    371.703017 | Stuart Humphries                                                                                                                                                      |
|  11 |    159.899035 |    666.294735 | Gopal Murali                                                                                                                                                          |
|  12 |    935.882967 |    527.889625 | NA                                                                                                                                                                    |
|  13 |    438.089332 |    264.019006 | Kamil S. Jaron                                                                                                                                                        |
|  14 |    371.120402 |    732.998933 | Margot Michaud                                                                                                                                                        |
|  15 |    777.699370 |    525.086187 | Kamil S. Jaron                                                                                                                                                        |
|  16 |     69.958791 |    456.332078 | Matt Crook                                                                                                                                                            |
|  17 |    550.556100 |    387.353635 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  18 |     99.489166 |    572.132418 | Matt Crook                                                                                                                                                            |
|  19 |    281.818659 |    534.481742 | Chase Brownstein                                                                                                                                                      |
|  20 |    612.605729 |    343.079182 | Chris huh                                                                                                                                                             |
|  21 |    823.312308 |    745.626791 | S.Martini                                                                                                                                                             |
|  22 |    861.038271 |     54.098400 | Zimices                                                                                                                                                               |
|  23 |    795.922235 |    290.748483 | Michelle Site                                                                                                                                                         |
|  24 |    129.959105 |     37.101918 | Caleb M. Brown                                                                                                                                                        |
|  25 |    612.809857 |    684.448481 | Carlos Cano-Barbacil                                                                                                                                                  |
|  26 |    539.966909 |    306.744561 | Caleb M. Brown                                                                                                                                                        |
|  27 |    379.614075 |     80.120033 | Javier Luque                                                                                                                                                          |
|  28 |    634.063810 |    188.289500 | Margot Michaud                                                                                                                                                        |
|  29 |    233.649401 |    757.062801 | Julio Garza                                                                                                                                                           |
|  30 |    341.990461 |    631.321924 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  31 |    553.167962 |    723.235523 | Andrew A. Farke                                                                                                                                                       |
|  32 |    916.279384 |    336.969483 | Julio Garza                                                                                                                                                           |
|  33 |    945.379413 |    160.066968 | Margot Michaud                                                                                                                                                        |
|  34 |     45.417333 |    285.961623 | Alexandre Vong                                                                                                                                                        |
|  35 |    947.889210 |    699.876004 | Gareth Monger                                                                                                                                                         |
|  36 |    768.116297 |     58.378338 | Rebecca Groom                                                                                                                                                         |
|  37 |    685.644934 |    600.327325 | CNZdenek                                                                                                                                                              |
|  38 |    815.344908 |    420.946090 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  39 |    791.917612 |    209.441508 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  40 |    930.701408 |    430.580673 | John Conway                                                                                                                                                           |
|  41 |    100.400232 |    766.104382 | Zimices                                                                                                                                                               |
|  42 |    494.309842 |    653.029573 | Steven Traver                                                                                                                                                         |
|  43 |     70.256183 |     81.515204 | Zimices                                                                                                                                                               |
|  44 |    216.446327 |    657.438573 | Alexis Simon                                                                                                                                                          |
|  45 |    535.976462 |    225.435544 | Andrés Sánchez                                                                                                                                                        |
|  46 |    331.193075 |    282.049970 | Maxime Dahirel                                                                                                                                                        |
|  47 |    345.181485 |    494.074902 | Emma Kissling                                                                                                                                                         |
|  48 |     61.983971 |    537.707237 | Gabriele Midolo                                                                                                                                                       |
|  49 |    713.490388 |    738.316491 | Kamil S. Jaron                                                                                                                                                        |
|  50 |    236.768189 |    140.976769 | Zimices                                                                                                                                                               |
|  51 |     78.639738 |    706.537731 | Emily Willoughby                                                                                                                                                      |
|  52 |     67.676949 |    422.574053 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  53 |    958.798581 |    651.081384 | Scott Hartman                                                                                                                                                         |
|  54 |    658.064200 |     69.587515 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  55 |    699.066602 |    386.205023 | Collin Gross                                                                                                                                                          |
|  56 |    697.361837 |    550.825462 | Steven Traver                                                                                                                                                         |
|  57 |    124.875882 |    269.996871 | Griensteidl and T. Michael Keesey                                                                                                                                     |
|  58 |    692.282954 |    269.425152 | Curtis Clark and T. Michael Keesey                                                                                                                                    |
|  59 |    959.043337 |    771.488206 | Andrew A. Farke                                                                                                                                                       |
|  60 |    439.286424 |    182.970861 | B. Duygu Özpolat                                                                                                                                                      |
|  61 |    555.357950 |    780.539399 | Sarah Werning                                                                                                                                                         |
|  62 |    244.999598 |    196.497753 | Tasman Dixon                                                                                                                                                          |
|  63 |    616.187904 |    544.222587 | NA                                                                                                                                                                    |
|  64 |    285.930376 |    359.941158 | Gareth Monger                                                                                                                                                         |
|  65 |    831.448698 |    170.777378 | Jagged Fang Designs                                                                                                                                                   |
|  66 |    958.526541 |    234.958087 | Inessa Voet                                                                                                                                                           |
|  67 |    917.596976 |     78.395713 | Gareth Monger                                                                                                                                                         |
|  68 |    989.036676 |    524.271340 | Bruno C. Vellutini                                                                                                                                                    |
|  69 |    448.991268 |    337.791995 | Chris huh                                                                                                                                                             |
|  70 |    280.050640 |    600.307150 | Scott Hartman                                                                                                                                                         |
|  71 |    113.885094 |    732.998195 | Smokeybjb                                                                                                                                                             |
|  72 |    389.025624 |    662.358215 | Ignacio Contreras                                                                                                                                                     |
|  73 |    701.980888 |    647.645314 | Steven Blackwood                                                                                                                                                      |
|  74 |    235.896691 |     35.995275 | Andrew Farke and Joseph Sertich                                                                                                                                       |
|  75 |    955.962027 |     42.337923 | Scott Hartman                                                                                                                                                         |
|  76 |    340.927391 |    586.292442 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
|  77 |    543.103999 |    755.377298 | Ignacio Contreras                                                                                                                                                     |
|  78 |    784.881763 |    593.860710 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  79 |    803.962698 |    369.011287 | Tracy A. Heath                                                                                                                                                        |
|  80 |     37.891275 |    603.511626 | Ferran Sayol                                                                                                                                                          |
|  81 |    606.268676 |     18.184513 | Matt Crook                                                                                                                                                            |
|  82 |    889.965374 |    705.437866 | Birgit Lang                                                                                                                                                           |
|  83 |    539.833038 |     36.019939 | Matt Crook                                                                                                                                                            |
|  84 |    912.058983 |    212.755284 | Matt Crook                                                                                                                                                            |
|  85 |    322.418233 |    790.605179 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
|  86 |    280.698131 |    370.451744 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
|  87 |    371.629578 |    704.623220 | M Kolmann                                                                                                                                                             |
|  88 |    881.816638 |    655.079947 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  89 |    220.885619 |    475.924012 | NA                                                                                                                                                                    |
|  90 |    711.019346 |    406.759385 | Jagged Fang Designs                                                                                                                                                   |
|  91 |    647.159388 |    624.507529 | Scott Hartman                                                                                                                                                         |
|  92 |    396.271160 |    591.803464 | Andrew A. Farke                                                                                                                                                       |
|  93 |     63.644486 |    677.790005 | Armin Reindl                                                                                                                                                          |
|  94 |     20.310651 |    771.787127 | Andy Wilson                                                                                                                                                           |
|  95 |    594.627992 |    625.586775 | Zimices                                                                                                                                                               |
|  96 |    665.066417 |    413.302826 | Carlos Cano-Barbacil                                                                                                                                                  |
|  97 |    384.062005 |    155.301226 | Matt Crook                                                                                                                                                            |
|  98 |    485.225670 |    178.990712 | NA                                                                                                                                                                    |
|  99 |    502.195382 |    701.054259 | Ignacio Contreras                                                                                                                                                     |
| 100 |    157.017826 |    439.748194 | Scott Hartman                                                                                                                                                         |
| 101 |    341.803016 |     16.906207 | Xavier Giroux-Bougard                                                                                                                                                 |
| 102 |    193.526854 |    563.710952 | Jagged Fang Designs                                                                                                                                                   |
| 103 |   1010.172471 |    192.383129 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 104 |    472.270457 |    110.177601 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 105 |    984.111313 |    271.821001 | Tasman Dixon                                                                                                                                                          |
| 106 |    131.737246 |    607.423420 | CNZdenek                                                                                                                                                              |
| 107 |     50.889745 |    360.814662 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                      |
| 108 |    385.165944 |    297.165189 | NA                                                                                                                                                                    |
| 109 |    457.717392 |    776.346010 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 110 |    888.938949 |     15.400944 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 111 |    449.549994 |    408.622466 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 112 |    651.806232 |    736.527048 | Lukasiniho                                                                                                                                                            |
| 113 |    933.895966 |    615.705839 | Emily Willoughby                                                                                                                                                      |
| 114 |    619.128779 |    256.039239 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 115 |    934.464926 |     11.832645 | T. Michael Keesey                                                                                                                                                     |
| 116 |    860.020991 |    579.641863 | Sean McCann                                                                                                                                                           |
| 117 |    667.992154 |    512.934521 | Matt Crook                                                                                                                                                            |
| 118 |     24.298194 |    506.888665 | Steven Traver                                                                                                                                                         |
| 119 |    501.058743 |    281.804619 | Ferran Sayol                                                                                                                                                          |
| 120 |    426.386192 |    390.823882 | Matt Crook                                                                                                                                                            |
| 121 |   1003.355740 |    583.208302 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 122 |    993.981104 |    259.495242 | Matt Crook                                                                                                                                                            |
| 123 |    220.643327 |    253.331446 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 124 |     96.642145 |    518.518999 | Melissa Broussard                                                                                                                                                     |
| 125 |    208.969604 |     74.170912 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 126 |    812.904323 |     36.540499 | Margot Michaud                                                                                                                                                        |
| 127 |    858.909108 |    200.920901 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 128 |    622.268992 |    781.010133 | Andrew A. Farke                                                                                                                                                       |
| 129 |    985.898050 |    708.841397 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 130 |    436.589838 |    137.864032 | Matt Crook                                                                                                                                                            |
| 131 |    186.719833 |    259.460088 | Zimices                                                                                                                                                               |
| 132 |     21.495474 |    591.781174 | Matt Crook                                                                                                                                                            |
| 133 |    372.812015 |     31.397726 | Alex Slavenko                                                                                                                                                         |
| 134 |    841.300739 |    189.715443 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                      |
| 135 |    747.941978 |    157.317347 | Gareth Monger                                                                                                                                                         |
| 136 |    699.044902 |    364.254966 | Lukas Panzarin                                                                                                                                                        |
| 137 |    734.804546 |    338.829742 | Steven Traver                                                                                                                                                         |
| 138 |     16.946601 |    370.732659 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 139 |    736.368282 |    300.887935 | Zimices                                                                                                                                                               |
| 140 |    469.640375 |     52.701571 | Birgit Lang                                                                                                                                                           |
| 141 |    595.526398 |    385.765346 | Margot Michaud                                                                                                                                                        |
| 142 |    293.470621 |    288.287130 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 143 |    585.531796 |    598.230642 | Jakovche                                                                                                                                                              |
| 144 |      8.842249 |     10.021876 | Zimices                                                                                                                                                               |
| 145 |    669.704023 |    478.676311 | Matt Crook                                                                                                                                                            |
| 146 |    932.797423 |    689.989049 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 147 |    361.408138 |    181.198932 | T. Michael Keesey                                                                                                                                                     |
| 148 |    744.468516 |    394.611361 | Chris huh                                                                                                                                                             |
| 149 |     14.232451 |     30.295157 | Zimices                                                                                                                                                               |
| 150 |    305.322801 |    448.709864 | Wayne Decatur                                                                                                                                                         |
| 151 |    481.185249 |    539.055173 | Ferran Sayol                                                                                                                                                          |
| 152 |    842.795151 |    555.856987 | T. Michael Keesey                                                                                                                                                     |
| 153 |    167.417121 |      3.514409 | Jagged Fang Designs                                                                                                                                                   |
| 154 |    336.301595 |    433.356571 | Zimices                                                                                                                                                               |
| 155 |    621.901033 |    654.140750 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 156 |    316.606041 |    396.780125 | Matt Crook                                                                                                                                                            |
| 157 |    735.765785 |    655.963518 | T. Michael Keesey                                                                                                                                                     |
| 158 |    674.440246 |    792.235337 | NA                                                                                                                                                                    |
| 159 |    130.468292 |    714.320630 | Ferran Sayol                                                                                                                                                          |
| 160 |    467.817071 |     26.297911 | Michael Scroggie                                                                                                                                                      |
| 161 |     89.700464 |    371.745246 | Matt Crook                                                                                                                                                            |
| 162 |    826.498475 |    270.714959 | Milton Tan                                                                                                                                                            |
| 163 |    335.787556 |    172.526939 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 164 |    622.609316 |    729.572047 | David Liao                                                                                                                                                            |
| 165 |    585.275041 |    465.074628 | Steven Traver                                                                                                                                                         |
| 166 |    970.776438 |    403.288823 | Steven Traver                                                                                                                                                         |
| 167 |    808.524358 |    305.741119 | NA                                                                                                                                                                    |
| 168 |    459.256732 |    168.123634 | Jagged Fang Designs                                                                                                                                                   |
| 169 |    486.609041 |    126.324377 | Zimices                                                                                                                                                               |
| 170 |     13.196861 |    675.103139 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 171 |    833.347361 |    476.043039 | Felix Vaux                                                                                                                                                            |
| 172 |    132.154713 |     15.560376 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                      |
| 173 |    614.647136 |    365.033470 | Mo Hassan                                                                                                                                                             |
| 174 |   1011.510042 |    691.628611 | Dean Schnabel                                                                                                                                                         |
| 175 |    754.613604 |    370.724166 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 176 |    287.478885 |    159.993750 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                         |
| 177 |    857.623941 |    364.413394 | Birgit Lang                                                                                                                                                           |
| 178 |    709.048444 |    193.097658 | François Michonneau                                                                                                                                                   |
| 179 |    483.171863 |    389.657384 | Gareth Monger                                                                                                                                                         |
| 180 |    746.436542 |    621.679260 | T. Michael Keesey                                                                                                                                                     |
| 181 |    250.034941 |     86.014222 | Michelle Site                                                                                                                                                         |
| 182 |    154.366745 |    409.547409 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 183 |    182.936758 |     83.806643 | Joanna Wolfe                                                                                                                                                          |
| 184 |    813.486306 |    488.494035 | Noah Schlottman                                                                                                                                                       |
| 185 |    597.630828 |    279.585629 | Markus A. Grohme                                                                                                                                                      |
| 186 |    176.356687 |    704.876846 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 187 |     23.464437 |     40.370907 | Jagged Fang Designs                                                                                                                                                   |
| 188 |    797.352613 |    335.879104 | wsnaccad                                                                                                                                                              |
| 189 |    155.068574 |    694.842237 | Matt Crook                                                                                                                                                            |
| 190 |    417.924904 |      8.308735 | Tasman Dixon                                                                                                                                                          |
| 191 |    301.477877 |    383.041256 | Matt Crook                                                                                                                                                            |
| 192 |    869.576249 |    788.012391 | Margot Michaud                                                                                                                                                        |
| 193 |    615.724774 |    132.094989 | Matt Crook                                                                                                                                                            |
| 194 |    619.716264 |    402.110229 | Ferran Sayol                                                                                                                                                          |
| 195 |    783.505235 |    307.061918 | NA                                                                                                                                                                    |
| 196 |    321.192352 |    340.866432 | NA                                                                                                                                                                    |
| 197 |    607.689387 |    157.991248 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 198 |    697.996583 |    413.418043 | Hugo Gruson                                                                                                                                                           |
| 199 |    633.774542 |    749.635810 | Matt Crook                                                                                                                                                            |
| 200 |    540.152161 |     14.807904 | Jagged Fang Designs                                                                                                                                                   |
| 201 |    397.991578 |    562.770845 | Tommaso Cancellario                                                                                                                                                   |
| 202 |    494.221069 |    523.797248 | Matt Crook                                                                                                                                                            |
| 203 |    257.818602 |    312.446180 | Emily Willoughby                                                                                                                                                      |
| 204 |    701.137004 |    351.652994 | Gareth Monger                                                                                                                                                         |
| 205 |    979.997179 |    613.847403 | Birgit Lang                                                                                                                                                           |
| 206 |    762.971644 |    704.436507 | Tasman Dixon                                                                                                                                                          |
| 207 |    276.120221 |     69.631159 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 208 |    161.432082 |     68.519182 | Zimices                                                                                                                                                               |
| 209 |    630.199432 |    140.944038 | Michael Day                                                                                                                                                           |
| 210 |    730.387784 |    687.476296 | Kai R. Caspar                                                                                                                                                         |
| 211 |    189.553200 |    532.533450 | Xavier Giroux-Bougard                                                                                                                                                 |
| 212 |    889.671864 |    452.314031 | Andy Wilson                                                                                                                                                           |
| 213 |    983.043007 |     80.537651 | Kamil S. Jaron                                                                                                                                                        |
| 214 |    573.303695 |     30.233849 | Ludwik Gąsiorowski                                                                                                                                                    |
| 215 |    635.034152 |     16.947510 | Maija Karala                                                                                                                                                          |
| 216 |    302.053240 |    338.492846 | Matt Crook                                                                                                                                                            |
| 217 |     11.039911 |    731.129744 | Christoph Schomburg                                                                                                                                                   |
| 218 |    144.146184 |    267.939208 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 219 |    884.531509 |    169.344535 | Ferran Sayol                                                                                                                                                          |
| 220 |    415.046523 |    616.861552 | Zimices                                                                                                                                                               |
| 221 |    182.264322 |    204.515987 | Andy Wilson                                                                                                                                                           |
| 222 |    361.946220 |    260.224741 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 223 |    766.581397 |    657.012663 | Andy Wilson                                                                                                                                                           |
| 224 |    919.044202 |    662.144951 | Gareth Monger                                                                                                                                                         |
| 225 |    172.193631 |    583.697228 | Beth Reinke                                                                                                                                                           |
| 226 |    584.722902 |    505.953844 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 227 |    915.198992 |    263.939511 | T. Michael Keesey                                                                                                                                                     |
| 228 |    641.725201 |    299.939306 | Agnello Picorelli                                                                                                                                                     |
| 229 |    617.993393 |    714.464452 | Jagged Fang Designs                                                                                                                                                   |
| 230 |    443.304363 |    305.413878 | Shyamal                                                                                                                                                               |
| 231 |    281.013456 |    410.627429 | Zimices                                                                                                                                                               |
| 232 |    887.147721 |    461.388845 | Darius Nau                                                                                                                                                            |
| 233 |    754.834320 |    443.679104 | Zimices                                                                                                                                                               |
| 234 |    891.562850 |    753.323971 | Steven Traver                                                                                                                                                         |
| 235 |     21.254855 |    147.060265 | Michael Scroggie                                                                                                                                                      |
| 236 |    972.508060 |    415.072324 | Birgit Lang                                                                                                                                                           |
| 237 |     87.627802 |    265.397742 | Ferran Sayol                                                                                                                                                          |
| 238 |    890.072180 |    227.005318 | Chris huh                                                                                                                                                             |
| 239 |    584.413821 |    737.825365 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 240 |    897.666747 |    502.660855 | Felix Vaux                                                                                                                                                            |
| 241 |    714.386217 |    491.720854 | Matt Crook                                                                                                                                                            |
| 242 |    612.846859 |    300.358106 | Chris Jennings (Risiatto)                                                                                                                                             |
| 243 |    274.687968 |    642.715832 | Anthony Caravaggi                                                                                                                                                     |
| 244 |    731.546079 |    517.136427 | Margot Michaud                                                                                                                                                        |
| 245 |    106.186646 |    485.803231 | Sharon Wegner-Larsen                                                                                                                                                  |
| 246 |    798.745407 |     37.829564 | Matt Crook                                                                                                                                                            |
| 247 |    596.136754 |    662.170221 | Zimices                                                                                                                                                               |
| 248 |    311.092720 |    668.615762 | Jimmy Bernot                                                                                                                                                          |
| 249 |    216.734181 |    272.160345 | Sarah Werning                                                                                                                                                         |
| 250 |    834.802551 |    538.883273 | Melissa Broussard                                                                                                                                                     |
| 251 |    865.112306 |    518.919197 | Scott Hartman                                                                                                                                                         |
| 252 |    506.276612 |    173.777152 | Michelle Site                                                                                                                                                         |
| 253 |    270.326216 |    501.197088 | Gareth Monger                                                                                                                                                         |
| 254 |    722.383085 |    668.833004 | Steven Traver                                                                                                                                                         |
| 255 |   1013.534163 |    170.372183 | Birgit Lang                                                                                                                                                           |
| 256 |    864.826410 |    502.263209 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 257 |    384.825434 |    687.030813 | Rebecca Groom                                                                                                                                                         |
| 258 |    640.104740 |    117.585237 | Matt Crook                                                                                                                                                            |
| 259 |    510.599682 |    133.935000 | Jagged Fang Designs                                                                                                                                                   |
| 260 |    562.787806 |    637.515883 | Steven Traver                                                                                                                                                         |
| 261 |    501.821738 |    236.024545 | (after Spotila 2004)                                                                                                                                                  |
| 262 |    233.598031 |    224.881838 | T. Michael Keesey                                                                                                                                                     |
| 263 |    124.846545 |    198.491309 | Matt Crook                                                                                                                                                            |
| 264 |    855.329374 |    169.700061 | Jagged Fang Designs                                                                                                                                                   |
| 265 |    329.558405 |    566.510386 | Margot Michaud                                                                                                                                                        |
| 266 |    983.922967 |    459.766632 | FJDegrange                                                                                                                                                            |
| 267 |    516.978807 |    150.685574 | Chris huh                                                                                                                                                             |
| 268 |    510.758310 |    335.608214 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 269 |    888.982772 |    778.166809 | Cesar Julian                                                                                                                                                          |
| 270 |    834.340075 |    495.682188 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 271 |    962.408841 |    434.043564 | Noah Schlottman                                                                                                                                                       |
| 272 |    604.632975 |    169.045536 | Sharon Wegner-Larsen                                                                                                                                                  |
| 273 |    394.849267 |    483.252413 | Jagged Fang Designs                                                                                                                                                   |
| 274 |    208.438316 |    551.417738 | Melissa Ingala                                                                                                                                                        |
| 275 |    702.067730 |    173.966812 | Matt Crook                                                                                                                                                            |
| 276 |    586.649390 |    236.154508 | Daniel Jaron                                                                                                                                                          |
| 277 |     57.350848 |    611.250696 | Chris huh                                                                                                                                                             |
| 278 |    841.580436 |    507.563245 | Gareth Monger                                                                                                                                                         |
| 279 |    515.573491 |     32.180717 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 280 |    470.020285 |    507.713597 | Martin R. Smith                                                                                                                                                       |
| 281 |    193.878416 |    484.937028 | Jiekun He                                                                                                                                                             |
| 282 |    473.416101 |    519.693250 | Matt Crook                                                                                                                                                            |
| 283 |    523.068281 |    490.223308 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 284 |    808.951096 |    571.066649 | Margot Michaud                                                                                                                                                        |
| 285 |    175.065465 |    685.867100 | Gareth Monger                                                                                                                                                         |
| 286 |    880.866502 |    244.960920 | Jagged Fang Designs                                                                                                                                                   |
| 287 |     60.321673 |    396.774399 | Birgit Lang                                                                                                                                                           |
| 288 |    902.175645 |    785.278433 | T. Michael Keesey                                                                                                                                                     |
| 289 |    913.616989 |    458.279305 | FJDegrange                                                                                                                                                            |
| 290 |    716.557637 |    615.585207 | Yan Wong                                                                                                                                                              |
| 291 |     18.776758 |    751.943807 | Chris A. Hamilton                                                                                                                                                     |
| 292 |    134.915791 |    457.057181 | Margot Michaud                                                                                                                                                        |
| 293 |    175.549500 |    156.997218 | Ryan Cupo                                                                                                                                                             |
| 294 |     66.606506 |    256.722812 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 295 |    742.991274 |    789.491406 | Birgit Lang                                                                                                                                                           |
| 296 |    589.200890 |    703.823025 | Zimices                                                                                                                                                               |
| 297 |    954.959508 |    381.127135 | NA                                                                                                                                                                    |
| 298 |    848.299867 |    723.196143 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 299 |    690.543090 |    512.323972 | Jack Mayer Wood                                                                                                                                                       |
| 300 |    107.842879 |    453.772042 | NA                                                                                                                                                                    |
| 301 |    764.053238 |    308.790114 | FunkMonk                                                                                                                                                              |
| 302 |    320.363164 |    511.247247 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 303 |   1015.500791 |    671.170282 | Skye McDavid                                                                                                                                                          |
| 304 |    416.167681 |    340.046514 | Gareth Monger                                                                                                                                                         |
| 305 |    607.865025 |    141.534232 | Zimices                                                                                                                                                               |
| 306 |    116.718262 |    327.175316 | Kamil S. Jaron                                                                                                                                                        |
| 307 |    227.586309 |     72.901857 | Jagged Fang Designs                                                                                                                                                   |
| 308 |    943.662542 |    401.528993 | Roberto Díaz Sibaja                                                                                                                                                   |
| 309 |    956.474899 |    601.222219 | Gareth Monger                                                                                                                                                         |
| 310 |    377.292139 |      2.328974 | Michelle Site                                                                                                                                                         |
| 311 |     59.198546 |    239.316274 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 312 |     44.472677 |    750.997148 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 313 |    175.564062 |    612.642259 | Michelle Site                                                                                                                                                         |
| 314 |    825.611024 |     94.981203 | Matt Crook                                                                                                                                                            |
| 315 |    232.185842 |    303.649216 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 316 |    828.130972 |    307.277154 | NA                                                                                                                                                                    |
| 317 |    529.986907 |    167.564479 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 318 |    623.335691 |    319.235801 | Scott Hartman                                                                                                                                                         |
| 319 |      9.126238 |    121.134404 | NA                                                                                                                                                                    |
| 320 |    502.091085 |    491.781805 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 321 |    135.105776 |    683.851170 | Zimices                                                                                                                                                               |
| 322 |    181.113485 |    494.748743 | Tracy A. Heath                                                                                                                                                        |
| 323 |    729.960379 |    614.261763 | Yan Wong from photo by Gyik Toma                                                                                                                                      |
| 324 |     80.344968 |    354.820443 | Maija Karala                                                                                                                                                          |
| 325 |    126.657626 |    630.199329 | Ignacio Contreras                                                                                                                                                     |
| 326 |    714.606263 |    158.429153 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 327 |    947.147331 |    627.322825 | Gareth Monger                                                                                                                                                         |
| 328 |    350.008987 |    548.109306 | Matt Crook                                                                                                                                                            |
| 329 |    603.043976 |    245.737988 | Mason McNair                                                                                                                                                          |
| 330 |   1009.161926 |    595.583448 | Margot Michaud                                                                                                                                                        |
| 331 |    746.593827 |    758.356101 | NA                                                                                                                                                                    |
| 332 |    590.746178 |    525.656849 | Dean Schnabel                                                                                                                                                         |
| 333 |    336.109847 |    419.298292 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 334 |    872.082764 |    554.130900 | Zimices                                                                                                                                                               |
| 335 |    756.723565 |    675.611393 | Geoff Shaw                                                                                                                                                            |
| 336 |    977.847343 |    680.638723 | Zimices                                                                                                                                                               |
| 337 |    874.961996 |    200.888418 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 338 |    266.996875 |    620.717851 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 339 |    772.986724 |    392.706883 | Karla Martinez                                                                                                                                                        |
| 340 |    316.641330 |      2.953055 | Christoph Schomburg                                                                                                                                                   |
| 341 |    575.810458 |     18.186369 | Tyler Greenfield                                                                                                                                                      |
| 342 |    133.926310 |    444.248904 | Jack Mayer Wood                                                                                                                                                       |
| 343 |    511.369471 |    417.052096 | CNZdenek                                                                                                                                                              |
| 344 |    243.038989 |     10.766139 | Matt Crook                                                                                                                                                            |
| 345 |     75.216165 |    657.211114 | Chris huh                                                                                                                                                             |
| 346 |    766.433044 |    755.450485 | Dean Schnabel                                                                                                                                                         |
| 347 |     95.613987 |    342.145565 | Margot Michaud                                                                                                                                                        |
| 348 |    463.889259 |      7.357922 | T. Michael Keesey                                                                                                                                                     |
| 349 |   1002.866824 |    413.424778 | Gareth Monger                                                                                                                                                         |
| 350 |   1008.451095 |     93.280220 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 351 |    495.175586 |     11.728883 | Martin R. Smith                                                                                                                                                       |
| 352 |    276.501928 |     34.951954 | Tracy A. Heath                                                                                                                                                        |
| 353 |    342.891548 |    164.119513 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 354 |    325.802706 |    205.873589 | Carlos Cano-Barbacil                                                                                                                                                  |
| 355 |    850.343795 |    296.008888 | Cesar Julian                                                                                                                                                          |
| 356 |     19.305574 |    449.709676 | Beth Reinke                                                                                                                                                           |
| 357 |    886.918688 |    498.893154 | Michael Scroggie                                                                                                                                                      |
| 358 |    742.269144 |    207.391803 | Steven Traver                                                                                                                                                         |
| 359 |    269.103167 |    663.147956 | NA                                                                                                                                                                    |
| 360 |    473.788489 |    288.245208 | Sarah Werning                                                                                                                                                         |
| 361 |    211.611378 |    106.846191 | Chuanixn Yu                                                                                                                                                           |
| 362 |    590.153286 |    368.153527 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 363 |    304.731216 |    756.890663 | Steven Traver                                                                                                                                                         |
| 364 |    754.723135 |    383.708218 | Ignacio Contreras                                                                                                                                                     |
| 365 |    483.994727 |    277.319041 | T. Michael Keesey                                                                                                                                                     |
| 366 |    901.325325 |    181.396578 | Scott Hartman                                                                                                                                                         |
| 367 |    529.968226 |    691.862121 | Scott Hartman                                                                                                                                                         |
| 368 |    123.350657 |    642.965524 | C. Camilo Julián-Caballero                                                                                                                                            |
| 369 |    244.539558 |    576.515024 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 370 |   1000.192587 |    112.131480 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 371 |   1005.124836 |    437.373137 | Rebecca Groom                                                                                                                                                         |
| 372 |    142.605227 |    794.600833 | NA                                                                                                                                                                    |
| 373 |    654.283976 |    665.625587 | Felix Vaux                                                                                                                                                            |
| 374 |    263.652577 |    697.910016 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 375 |    523.003326 |    327.370357 | Markus A. Grohme                                                                                                                                                      |
| 376 |    486.449041 |     32.181362 | NA                                                                                                                                                                    |
| 377 |    691.809997 |    493.146822 | Gareth Monger                                                                                                                                                         |
| 378 |    460.178086 |    524.155205 | Tauana J. Cunha                                                                                                                                                       |
| 379 |     58.572794 |    111.503321 | Henry Lydecker                                                                                                                                                        |
| 380 |    646.703737 |    141.408221 | Skye M                                                                                                                                                                |
| 381 |    141.751617 |    468.129841 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 382 |    232.760832 |    708.704655 | Ben Liebeskind                                                                                                                                                        |
| 383 |    644.739220 |    320.573861 | Gareth Monger                                                                                                                                                         |
| 384 |    545.558791 |    409.699039 | Dean Schnabel                                                                                                                                                         |
| 385 |    146.559703 |     86.796414 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 386 |    952.460638 |    270.427305 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 387 |    683.804643 |    749.269476 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 388 |    752.217476 |     32.107429 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 389 |    414.634214 |    134.029109 | T. Michael Keesey                                                                                                                                                     |
| 390 |    944.878672 |    554.813184 | Scott Hartman                                                                                                                                                         |
| 391 |    171.313127 |    476.571230 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 392 |    278.846046 |     51.115958 | Zimices                                                                                                                                                               |
| 393 |    289.467882 |    472.896992 | Noah Schlottman                                                                                                                                                       |
| 394 |    914.478022 |    628.720462 | Alex Slavenko                                                                                                                                                         |
| 395 |    639.906763 |    246.190017 | Ferran Sayol                                                                                                                                                          |
| 396 |    837.487319 |    522.099656 | Noah Schlottman                                                                                                                                                       |
| 397 |     27.313652 |    472.447248 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 398 |    258.324354 |    481.337848 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 399 |    104.660872 |    665.926594 | Steven Traver                                                                                                                                                         |
| 400 |    337.006670 |    780.860462 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 401 |    319.470463 |     37.903117 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 402 |    328.079006 |    409.079361 | Steven Traver                                                                                                                                                         |
| 403 |    561.605231 |    136.242866 | Margot Michaud                                                                                                                                                        |
| 404 |    357.705081 |    331.178410 | Matt Crook                                                                                                                                                            |
| 405 |    596.582026 |    760.524727 | Steven Traver                                                                                                                                                         |
| 406 |     53.684131 |    790.547558 | Markus A. Grohme                                                                                                                                                      |
| 407 |    646.440734 |    781.826882 | Ferran Sayol                                                                                                                                                          |
| 408 |    648.965333 |    378.067041 | Markus A. Grohme                                                                                                                                                      |
| 409 |    732.465590 |    416.207846 | \[unknown\]                                                                                                                                                           |
| 410 |    264.480268 |     96.700785 | Andy Wilson                                                                                                                                                           |
| 411 |    651.509576 |    128.322542 | Felix Vaux                                                                                                                                                            |
| 412 |    772.667256 |    460.862056 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 413 |     20.504231 |    720.360013 | Gareth Monger                                                                                                                                                         |
| 414 |     26.938556 |    530.054728 | Michelle Site                                                                                                                                                         |
| 415 |    506.298058 |     21.553599 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 416 |    713.021698 |    427.948722 | Zimices                                                                                                                                                               |
| 417 |   1006.441673 |     16.077014 | Birgit Lang                                                                                                                                                           |
| 418 |    781.844336 |     17.421319 | Gareth Monger                                                                                                                                                         |
| 419 |    473.858001 |    739.032233 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 420 |    605.055871 |    120.731912 | Alexandre Vong                                                                                                                                                        |
| 421 |    998.050659 |    478.801347 | Sebastian Stabinger                                                                                                                                                   |
| 422 |    651.338742 |    241.445371 | Margot Michaud                                                                                                                                                        |
| 423 |     73.561793 |    475.254619 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 424 |    713.599048 |    205.675984 | Christoph Schomburg                                                                                                                                                   |
| 425 |    382.033524 |    561.372735 | Chris huh                                                                                                                                                             |
| 426 |    387.300044 |    467.309423 | Jagged Fang Designs                                                                                                                                                   |
| 427 |    177.845639 |    178.575732 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 428 |    311.952060 |    131.335620 | Gareth Monger                                                                                                                                                         |
| 429 |    983.426829 |    555.852887 | Markus A. Grohme                                                                                                                                                      |
| 430 |    887.041267 |    210.640574 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 431 |   1001.091803 |    669.710898 | Prathyush Thomas                                                                                                                                                      |
| 432 |     35.112537 |    324.813678 | Hugo Gruson                                                                                                                                                           |
| 433 |    421.992527 |    678.029814 | NA                                                                                                                                                                    |
| 434 |    100.423988 |    637.060860 | Collin Gross                                                                                                                                                          |
| 435 |    720.080007 |     79.994554 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 436 |    497.691993 |    107.276543 | Steven Traver                                                                                                                                                         |
| 437 |    658.924777 |    783.189713 | Dean Schnabel                                                                                                                                                         |
| 438 |   1000.377584 |    743.184479 | Margot Michaud                                                                                                                                                        |
| 439 |    498.623367 |    711.011728 | Markus A. Grohme                                                                                                                                                      |
| 440 |    182.544641 |    448.105312 | Matt Crook                                                                                                                                                            |
| 441 |    385.598357 |    335.418064 | Michael Scroggie                                                                                                                                                      |
| 442 |    623.030804 |    626.224514 | NA                                                                                                                                                                    |
| 443 |    123.383295 |    688.646260 | Steven Traver                                                                                                                                                         |
| 444 |    654.153673 |    752.419251 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 445 |    259.706050 |    639.769067 | Matt Crook                                                                                                                                                            |
| 446 |    337.901960 |    690.663416 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 447 |    504.863712 |    218.534926 | Zimices                                                                                                                                                               |
| 448 |    490.072338 |    227.136810 | Shyamal                                                                                                                                                               |
| 449 |    636.821337 |    760.106361 | Margot Michaud                                                                                                                                                        |
| 450 |    967.398253 |    563.163070 | Chris huh                                                                                                                                                             |
| 451 |     89.281153 |     44.882123 | Yan Wong                                                                                                                                                              |
| 452 |    595.522134 |    265.470222 | Collin Gross                                                                                                                                                          |
| 453 |    184.712617 |    239.589532 | Tracy A. Heath                                                                                                                                                        |
| 454 |    303.136440 |    204.677015 | Margot Michaud                                                                                                                                                        |
| 455 |    891.220744 |    624.583687 | T. Michael Keesey                                                                                                                                                     |
| 456 |    398.549429 |    477.457277 | Beth Reinke                                                                                                                                                           |
| 457 |    972.705239 |    256.040039 | FJDegrange                                                                                                                                                            |
| 458 |    297.083810 |    578.996657 | Jagged Fang Designs                                                                                                                                                   |
| 459 |    582.146184 |    287.950726 | Zimices                                                                                                                                                               |
| 460 |   1008.252138 |    765.071466 | Cristopher Silva                                                                                                                                                      |
| 461 |    718.174199 |     91.707317 | Roberto Díaz Sibaja                                                                                                                                                   |
| 462 |     91.289425 |     18.223460 | Andy Wilson                                                                                                                                                           |
| 463 |    417.872782 |    415.298507 | Michael P. Taylor                                                                                                                                                     |
| 464 |    820.509420 |    508.860416 | Tasman Dixon                                                                                                                                                          |
| 465 |    479.007424 |    312.797996 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 466 |     77.673492 |    238.616458 | Zimices                                                                                                                                                               |
| 467 |     22.532871 |    711.107002 | Sharon Wegner-Larsen                                                                                                                                                  |
| 468 |    615.823872 |    476.224291 | Emily Willoughby                                                                                                                                                      |
| 469 |    174.396295 |    636.027264 | Andy Wilson                                                                                                                                                           |
| 470 |    594.787629 |    554.808556 | Matt Crook                                                                                                                                                            |
| 471 |    503.525109 |    357.961266 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 472 |    337.737468 |    158.934080 | Birgit Lang                                                                                                                                                           |
| 473 |    926.670567 |    399.972084 | Zimices                                                                                                                                                               |
| 474 |    148.019149 |    747.972583 | NA                                                                                                                                                                    |
| 475 |    233.752179 |    323.593599 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 476 |     73.500557 |    341.653340 | Ferran Sayol                                                                                                                                                          |
| 477 |    528.546167 |    355.879701 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 478 |     32.025187 |    390.255475 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 479 |    180.106878 |    416.747030 | (after McCulloch 1908)                                                                                                                                                |
| 480 |    869.155169 |    762.996154 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 481 |     97.191305 |    209.625520 | Zimices                                                                                                                                                               |
| 482 |     19.730915 |      4.349481 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 483 |    144.354938 |    589.904445 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 484 |    870.488683 |    639.683617 | Tauana J. Cunha                                                                                                                                                       |
| 485 |   1006.937262 |    382.832732 | Zimices                                                                                                                                                               |
| 486 |    346.720802 |    442.422800 | Jagged Fang Designs                                                                                                                                                   |
| 487 |     13.657645 |    701.805411 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 488 |    959.741375 |     11.295116 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 489 |     16.946265 |    683.322164 | Matt Crook                                                                                                                                                            |
| 490 |    262.569289 |     77.926281 | Tasman Dixon                                                                                                                                                          |
| 491 |    761.581875 |    322.278475 | Margot Michaud                                                                                                                                                        |
| 492 |    467.918279 |    790.594496 | Zimices                                                                                                                                                               |
| 493 |    874.819501 |    613.172028 | Andy Wilson                                                                                                                                                           |
| 494 |    909.141924 |    680.420646 | Margot Michaud                                                                                                                                                        |
| 495 |    496.208032 |    739.626554 | Tasman Dixon                                                                                                                                                          |
| 496 |    479.593477 |    353.949737 | Zimices                                                                                                                                                               |
| 497 |    582.660267 |    636.055056 | T. Michael Keesey                                                                                                                                                     |
| 498 |    816.843298 |    325.544510 | Steven Traver                                                                                                                                                         |
| 499 |    186.161371 |    270.670898 | Zimices                                                                                                                                                               |
| 500 |     16.984549 |    555.990378 | Chris huh                                                                                                                                                             |
| 501 |    744.568491 |    716.056611 | Tasman Dixon                                                                                                                                                          |
| 502 |    643.484399 |    470.036677 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 503 |    777.741728 |    412.341153 | Ferran Sayol                                                                                                                                                          |
| 504 |    451.939345 |    200.118501 | Erika Schumacher                                                                                                                                                      |
| 505 |    887.131841 |    472.748829 | Matt Crook                                                                                                                                                            |
| 506 |    996.426080 |    681.796924 | Zimices                                                                                                                                                               |
| 507 |    476.143309 |    493.560453 | Darius Nau                                                                                                                                                            |
| 508 |    737.089743 |    486.063961 | Matt Crook                                                                                                                                                            |
| 509 |    428.083612 |    613.485732 | Zimices                                                                                                                                                               |
| 510 |    492.424630 |    502.144968 | Roberto Díaz Sibaja                                                                                                                                                   |
| 511 |    664.874513 |     38.741870 | NA                                                                                                                                                                    |
| 512 |    257.254141 |    326.417346 | Jagged Fang Designs                                                                                                                                                   |
| 513 |    667.813466 |     17.834671 | Mo Hassan                                                                                                                                                             |
| 514 |    188.940384 |    593.256426 | Kailah Thorn & Ben King                                                                                                                                               |
| 515 |    918.826211 |    791.206184 | Oliver Voigt                                                                                                                                                          |
| 516 |    644.694388 |    155.024366 | Zimices                                                                                                                                                               |
| 517 |    664.419115 |    491.361586 | Jagged Fang Designs                                                                                                                                                   |
| 518 |    496.968328 |    246.775831 | xgirouxb                                                                                                                                                              |
| 519 |    308.985793 |    458.733848 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 520 |    951.426922 |    583.121970 | Xavier Giroux-Bougard                                                                                                                                                 |
| 521 |    693.546117 |      9.320735 | Henry Lydecker                                                                                                                                                        |
| 522 |    690.468808 |    696.343699 | Ignacio Contreras                                                                                                                                                     |
| 523 |    733.717557 |    174.752042 | Sarah Werning                                                                                                                                                         |
| 524 |   1006.680580 |    122.717695 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 525 |     59.975513 |     35.431362 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 526 |    400.886883 |    312.860993 | ArtFavor & annaleeblysse                                                                                                                                              |
| 527 |    986.402133 |    102.550495 | NA                                                                                                                                                                    |
| 528 |    451.364135 |    207.984300 | Gareth Monger                                                                                                                                                         |
| 529 |    403.870382 |     12.260775 | Samanta Orellana                                                                                                                                                      |
| 530 |    854.691446 |    488.339475 | Gareth Monger                                                                                                                                                         |
| 531 |    549.244080 |    506.048096 | Collin Gross                                                                                                                                                          |
| 532 |    138.758904 |    415.989501 | Jagged Fang Designs                                                                                                                                                   |
| 533 |    676.663140 |    213.714949 | Hugo Gruson                                                                                                                                                           |
| 534 |    826.087713 |    719.599884 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 535 |    784.079371 |    790.798485 | Alex Slavenko                                                                                                                                                         |
| 536 |    833.433620 |    393.932944 | Matt Crook                                                                                                                                                            |
| 537 |    769.078321 |    232.201744 | NA                                                                                                                                                                    |
| 538 |    123.723949 |    576.126549 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 539 |    612.001285 |    613.014712 | Markus A. Grohme                                                                                                                                                      |
| 540 |    714.081366 |    679.798334 | Steven Traver                                                                                                                                                         |
| 541 |    771.429319 |    342.934489 | Terpsichores                                                                                                                                                          |
| 542 |    324.758884 |    156.931442 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 543 |    128.878642 |    615.813143 | Tasman Dixon                                                                                                                                                          |
| 544 |     76.936636 |    119.396347 | Scott Reid                                                                                                                                                            |
| 545 |     81.747653 |    666.311367 | NA                                                                                                                                                                    |
| 546 |    125.162993 |    489.071517 | Ieuan Jones                                                                                                                                                           |
| 547 |    636.437755 |    787.048594 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 548 |   1012.915562 |     76.864292 | Margot Michaud                                                                                                                                                        |
| 549 |    265.296967 |      6.613706 | Dmitry Bogdanov                                                                                                                                                       |
| 550 |    792.017044 |     46.860033 | Neil Kelley                                                                                                                                                           |
| 551 |     41.369591 |    460.200949 | Matt Crook                                                                                                                                                            |
| 552 |    170.883839 |     53.494323 | Zimices / Julián Bayona                                                                                                                                               |
| 553 |    714.168597 |    219.556331 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 554 |    258.387292 |    671.050168 | Arthur S. Brum                                                                                                                                                        |
| 555 |    873.634018 |    714.306604 | Zimices                                                                                                                                                               |
| 556 |     47.282720 |    375.404669 | Smokeybjb                                                                                                                                                             |
| 557 |    488.541316 |    767.627555 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 558 |    744.409568 |    437.789401 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 559 |    241.431423 |    214.870309 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 560 |    483.652227 |    206.243736 | Margot Michaud                                                                                                                                                        |
| 561 |    728.127388 |    511.724534 | Mike Hanson                                                                                                                                                           |
| 562 |    428.679461 |    793.014749 | Zimices                                                                                                                                                               |
| 563 |    104.810651 |    196.381891 | NA                                                                                                                                                                    |
| 564 |    597.191562 |    488.598099 | Zimices                                                                                                                                                               |
| 565 |     91.845404 |    470.957914 | Jakovche                                                                                                                                                              |
| 566 |    841.580689 |     86.500646 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 567 |    932.093310 |     90.658963 | Beth Reinke                                                                                                                                                           |
| 568 |    771.232852 |     35.179567 | Tracy A. Heath                                                                                                                                                        |
| 569 |    849.772931 |    431.083839 | Matt Crook                                                                                                                                                            |
| 570 |    821.320653 |    557.748095 | Jagged Fang Designs                                                                                                                                                   |
| 571 |    614.027120 |    735.801706 | T. Michael Keesey                                                                                                                                                     |
| 572 |    957.685840 |    723.266393 | Gareth Monger                                                                                                                                                         |
| 573 |    548.403943 |    159.484091 | Matt Crook                                                                                                                                                            |
| 574 |    667.549135 |    237.477593 | Lukasiniho                                                                                                                                                            |
| 575 |    377.255847 |    629.728861 | Ben Liebeskind                                                                                                                                                        |
| 576 |    936.880567 |    265.868829 | Esme Ashe-Jepson                                                                                                                                                      |
| 577 |     60.208523 |     18.393393 | Ferran Sayol                                                                                                                                                          |
| 578 |    934.420048 |    412.077106 | Jagged Fang Designs                                                                                                                                                   |
| 579 |    483.200448 |    785.852731 | Michelle Site                                                                                                                                                         |
| 580 |    885.667857 |    255.960311 | L. Shyamal                                                                                                                                                            |
| 581 |    865.413660 |    255.194211 | Margot Michaud                                                                                                                                                        |
| 582 |    718.753450 |    320.716577 | NA                                                                                                                                                                    |
| 583 |    499.467293 |    195.020517 | Gareth Monger                                                                                                                                                         |
| 584 |    794.505845 |    290.525923 | Andrew A. Farke                                                                                                                                                       |
| 585 |    841.640439 |    100.134802 | Zimices                                                                                                                                                               |
| 586 |    257.184739 |    691.033957 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                         |
| 587 |    693.115662 |    371.721230 | Oscar Sanisidro                                                                                                                                                       |
| 588 |     19.263955 |    543.792480 | FunkMonk                                                                                                                                                              |
| 589 |    307.645912 |    159.688011 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 590 |    219.940767 |     92.325797 | Noah Schlottman                                                                                                                                                       |
| 591 |    580.316654 |    790.977674 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 592 |    424.166874 |    634.997086 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 593 |     22.046631 |     23.871084 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 594 |     37.299071 |    747.341536 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 595 |    612.556727 |    466.599872 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 596 |    657.432880 |    318.480081 | Matt Crook                                                                                                                                                            |
| 597 |    567.949321 |    664.325403 | Mattia Menchetti                                                                                                                                                      |
| 598 |    690.225454 |    773.254073 | Mathieu Pélissié                                                                                                                                                      |
| 599 |    645.449225 |    512.016136 | Steven Traver                                                                                                                                                         |
| 600 |    266.719034 |    517.301840 | T. Michael Keesey                                                                                                                                                     |
| 601 |    523.315901 |    510.763291 | Sarah Werning                                                                                                                                                         |
| 602 |    800.638989 |    785.021962 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 603 |    693.176950 |    685.144862 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 604 |    158.557673 |    784.397759 | Julio Garza                                                                                                                                                           |
| 605 |    564.702253 |     53.483168 | Matt Crook                                                                                                                                                            |
| 606 |    678.292139 |    681.846018 | Dmitry Bogdanov                                                                                                                                                       |
| 607 |    628.275178 |    401.696897 | Steven Traver                                                                                                                                                         |
| 608 |     99.629394 |    283.074029 | Cesar Julian                                                                                                                                                          |
| 609 |    161.431418 |    205.305446 | Zimices                                                                                                                                                               |
| 610 |   1013.038694 |    490.041969 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 611 |    948.364377 |    561.528189 | Chuanixn Yu                                                                                                                                                           |
| 612 |    818.962442 |    318.252650 | Gareth Monger                                                                                                                                                         |
| 613 |    853.940809 |    277.528928 | Dmitry Bogdanov                                                                                                                                                       |
| 614 |     94.552126 |    450.680586 | Margot Michaud                                                                                                                                                        |
| 615 |    214.053273 |    532.147706 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 616 |    690.420418 |    788.957525 | Abraão B. Leite                                                                                                                                                       |
| 617 |    880.153961 |    690.962191 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 618 |    308.602025 |    614.908854 | Dean Schnabel                                                                                                                                                         |
| 619 |    675.301808 |    321.487749 | Tasman Dixon                                                                                                                                                          |
| 620 |    834.319642 |    283.432360 | Andy Wilson                                                                                                                                                           |
| 621 |    981.899974 |    632.869709 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 622 |     37.903762 |    580.446600 | Scott Hartman                                                                                                                                                         |
| 623 |    295.769475 |     78.709934 | Christine Axon                                                                                                                                                        |
| 624 |    577.656992 |    272.763100 | Chris huh                                                                                                                                                             |
| 625 |    744.958745 |    690.823012 | T. Michael Keesey                                                                                                                                                     |
| 626 |    552.868142 |    342.833730 | Zimices                                                                                                                                                               |
| 627 |     79.513725 |    677.832663 | Zimices                                                                                                                                                               |
| 628 |    252.774396 |    374.170414 | Margot Michaud                                                                                                                                                        |
| 629 |    753.605727 |    347.000470 | Scott Hartman                                                                                                                                                         |
| 630 |    638.791750 |    582.538244 | Melissa Broussard                                                                                                                                                     |
| 631 |    343.828518 |    194.619669 | B. Duygu Özpolat                                                                                                                                                      |
| 632 |    559.320386 |    409.560904 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 633 |    619.324771 |    794.569736 | M Kolmann                                                                                                                                                             |
| 634 |    351.234770 |    213.644511 | Zimices                                                                                                                                                               |
| 635 |    867.815416 |    475.881176 | Felix Vaux                                                                                                                                                            |
| 636 |    243.238390 |    710.050623 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 637 |    107.176676 |    441.034475 | Maija Karala                                                                                                                                                          |
| 638 |    305.665327 |     22.953015 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 639 |    100.094258 |    292.029192 | Chris huh                                                                                                                                                             |
| 640 |    379.894430 |    607.223046 | Markus A. Grohme                                                                                                                                                      |
| 641 |    204.383059 |    501.058995 | Francesca Belem Lopes Palmeira                                                                                                                                        |
| 642 |    100.939305 |    402.471871 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 643 |    337.537126 |    531.014538 | Steven Coombs                                                                                                                                                         |
| 644 |    465.215933 |    694.266998 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 645 |    374.176603 |    269.422438 | C. Camilo Julián-Caballero                                                                                                                                            |
| 646 |    712.153067 |    396.227863 | Kent Elson Sorgon                                                                                                                                                     |
| 647 |    799.428286 |      8.831070 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 648 |    787.626789 |    391.313792 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 649 |    311.059521 |    187.724585 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 650 |    710.197422 |    472.248724 | Zimices / Julián Bayona                                                                                                                                               |
| 651 |    161.451936 |    490.393224 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 652 |   1011.121521 |    311.520036 | Matt Crook                                                                                                                                                            |
| 653 |    181.668970 |    737.347335 | Sean McCann                                                                                                                                                           |
| 654 |      6.492387 |    428.656218 | NA                                                                                                                                                                    |
| 655 |    722.097894 |    187.797491 | Kanchi Nanjo                                                                                                                                                          |
| 656 |    448.339417 |     24.478948 | NA                                                                                                                                                                    |
| 657 |    348.986113 |    179.294739 | Steven Traver                                                                                                                                                         |
| 658 |    367.331275 |    479.550545 | Maxime Dahirel                                                                                                                                                        |
| 659 |    154.835319 |    459.032502 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 660 |    561.674995 |    174.489797 | Anthony Caravaggi                                                                                                                                                     |
| 661 |    823.084025 |     18.621859 | Ferran Sayol                                                                                                                                                          |
| 662 |    752.999379 |    421.213032 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 663 |    283.204835 |    169.938162 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 664 |    992.452569 |     15.353230 | Iain Reid                                                                                                                                                             |
| 665 |    249.915166 |    470.959751 | Matt Crook                                                                                                                                                            |
| 666 |    836.244267 |    378.673121 | Michelle Site                                                                                                                                                         |
| 667 |    151.323080 |    163.808463 | Emily Willoughby                                                                                                                                                      |
| 668 |    289.074234 |    188.683671 | Zimices                                                                                                                                                               |
| 669 |    871.889545 |    225.246588 | Javier Luque                                                                                                                                                          |
| 670 |    996.312739 |    209.146276 | Matt Martyniuk                                                                                                                                                        |
| 671 |    469.886296 |    374.731628 | Margot Michaud                                                                                                                                                        |
| 672 |     18.391686 |    430.874789 | Margot Michaud                                                                                                                                                        |
| 673 |    873.522341 |    358.584927 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 674 |    224.894581 |    168.167553 | Joanna Wolfe                                                                                                                                                          |
| 675 |    660.891494 |    771.874977 | Yan Wong                                                                                                                                                              |
| 676 |     12.419514 |     45.044033 | Samanta Orellana                                                                                                                                                      |
| 677 |    619.578406 |    378.463517 | Noah Schlottman                                                                                                                                                       |
| 678 |    852.681554 |      5.878618 | Bennet McComish, photo by Avenue                                                                                                                                      |
| 679 |    746.263800 |    733.627602 | Margot Michaud                                                                                                                                                        |
| 680 |    271.982851 |    152.412315 | Ferran Sayol                                                                                                                                                          |
| 681 |    188.597744 |     59.628135 | Matt Crook                                                                                                                                                            |
| 682 |    141.709598 |    522.361132 | Martin R. Smith                                                                                                                                                       |
| 683 |    996.845021 |    632.376825 | Jagged Fang Designs                                                                                                                                                   |
| 684 |    695.530735 |    155.666818 | Mason McNair                                                                                                                                                          |
| 685 |    135.009928 |    434.436904 | Matt Crook                                                                                                                                                            |
| 686 |    845.819338 |    598.846009 | Ferran Sayol                                                                                                                                                          |
| 687 |     14.129678 |    603.441780 | Matt Crook                                                                                                                                                            |
| 688 |    599.090107 |    670.876168 | Manabu Bessho-Uehara                                                                                                                                                  |
| 689 |    567.422419 |    278.712453 | NA                                                                                                                                                                    |
| 690 |    466.865911 |    415.753439 | Margot Michaud                                                                                                                                                        |
| 691 |    327.951076 |    471.713411 | Kai R. Caspar                                                                                                                                                         |
| 692 |    763.383814 |    589.275873 | Margot Michaud                                                                                                                                                        |
| 693 |    650.869177 |    484.876763 | Armin Reindl                                                                                                                                                          |
| 694 |    323.175976 |    379.225390 | Ferran Sayol                                                                                                                                                          |
| 695 |    691.203795 |    670.926661 | Alex Slavenko                                                                                                                                                         |
| 696 |    760.925581 |    356.188237 | T. Michael Keesey                                                                                                                                                     |
| 697 |    377.646784 |    128.727758 | NA                                                                                                                                                                    |
| 698 |    697.137468 |    554.656857 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 699 |    162.853395 |    428.767356 | Scott Hartman                                                                                                                                                         |
| 700 |    858.522850 |     18.352919 | Javier Luque & Sarah Gerken                                                                                                                                           |
| 701 |   1015.764298 |     65.012390 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 702 |    773.805714 |    246.447873 | Ingo Braasch                                                                                                                                                          |
| 703 |    873.899346 |    519.694478 | Gareth Monger                                                                                                                                                         |
| 704 |    453.692099 |    289.461831 | Margot Michaud                                                                                                                                                        |
| 705 |    825.568253 |    297.205569 | Matt Crook                                                                                                                                                            |
| 706 |    189.176733 |    505.922649 | Maija Karala                                                                                                                                                          |
| 707 |    648.375088 |    558.821437 | Margot Michaud                                                                                                                                                        |
| 708 |    295.989112 |    782.583052 | NA                                                                                                                                                                    |
| 709 |    284.599248 |    148.787959 | Tasman Dixon                                                                                                                                                          |
| 710 |    382.037279 |    545.988158 | Zimices                                                                                                                                                               |
| 711 |    474.526460 |    244.959920 | Tasman Dixon                                                                                                                                                          |
| 712 |    303.975634 |      7.796304 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 713 |    665.812620 |    132.961101 | Kanchi Nanjo                                                                                                                                                          |
| 714 |    672.702419 |    720.899841 | Becky Barnes                                                                                                                                                          |
| 715 |    474.072129 |    700.588374 | Tod Robbins                                                                                                                                                           |
| 716 |    271.270396 |    210.862948 | T. Michael Keesey                                                                                                                                                     |
| 717 |    290.941986 |    223.364676 | Andy Wilson                                                                                                                                                           |
| 718 |    814.139630 |    288.275718 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 719 |    964.490747 |    455.489341 | NA                                                                                                                                                                    |
| 720 |    168.888948 |    751.250857 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 721 |    728.643335 |     13.207903 | Steven Traver                                                                                                                                                         |
| 722 |    234.854447 |     95.349430 | Margot Michaud                                                                                                                                                        |
| 723 |    257.957975 |    222.101379 | Scott Hartman                                                                                                                                                         |
| 724 |   1006.601921 |    725.322865 | Rafael Maia                                                                                                                                                           |
| 725 |    737.190585 |    669.406744 | Ferran Sayol                                                                                                                                                          |
| 726 |    581.115639 |      2.438568 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 727 |     13.537766 |    353.952208 | Ingo Braasch                                                                                                                                                          |
| 728 |      6.076807 |    192.767880 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 729 |    459.149167 |     31.182315 | NA                                                                                                                                                                    |
| 730 |   1014.341357 |    247.509178 | NA                                                                                                                                                                    |
| 731 |    936.322499 |    102.753492 | Steven Traver                                                                                                                                                         |
| 732 |    867.866520 |    684.180659 | Tracy A. Heath                                                                                                                                                        |
| 733 |    879.798812 |    430.045376 | Maxime Dahirel                                                                                                                                                        |
| 734 |     76.475027 |    485.829842 | Julio Garza                                                                                                                                                           |
| 735 |   1005.714761 |    396.955857 | Matt Crook                                                                                                                                                            |
| 736 |    498.358406 |    267.411829 | Anthony Caravaggi                                                                                                                                                     |
| 737 |    286.880980 |    620.341643 | Gareth Monger                                                                                                                                                         |
| 738 |     31.163494 |    118.092685 | Margot Michaud                                                                                                                                                        |
| 739 |    689.244508 |     32.871228 | Alex Slavenko                                                                                                                                                         |
| 740 |    354.315196 |    691.010280 | Kamil S. Jaron                                                                                                                                                        |
| 741 |    942.680357 |    596.656010 | Matt Crook                                                                                                                                                            |
| 742 |    875.116181 |    625.977068 | Margot Michaud                                                                                                                                                        |
| 743 |    878.543390 |    436.039795 | Chris huh                                                                                                                                                             |
| 744 |    855.140830 |    189.016497 | Matt Crook                                                                                                                                                            |
| 745 |    283.826084 |    480.268161 | Zimices                                                                                                                                                               |
| 746 |    329.995096 |    133.709482 | Scott Hartman                                                                                                                                                         |
| 747 |    375.052723 |    577.250571 | Matt Crook                                                                                                                                                            |
| 748 |     14.101683 |    385.305804 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 749 |    908.847170 |    697.624362 | Matt Crook                                                                                                                                                            |
| 750 |    868.215027 |    444.004131 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                            |
| 751 |    755.399368 |    599.855480 | Emily Willoughby                                                                                                                                                      |
| 752 |    532.845881 |    498.434659 | T. Michael Keesey                                                                                                                                                     |
| 753 |    427.248050 |     24.230048 | Ingo Braasch                                                                                                                                                          |
| 754 |     99.062348 |    682.645530 | Felix Vaux                                                                                                                                                            |
| 755 |    286.586173 |    399.329909 | Steven Traver                                                                                                                                                         |
| 756 |    903.170427 |    457.683709 | Ferran Sayol                                                                                                                                                          |
| 757 |    377.458876 |    700.942508 | NA                                                                                                                                                                    |
| 758 |    876.884430 |    105.114857 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 759 |    599.547935 |    713.773147 | Tasman Dixon                                                                                                                                                          |
| 760 |    150.966861 |    487.398152 | Zimices                                                                                                                                                               |
| 761 |    547.468958 |    517.024113 | Scott Hartman                                                                                                                                                         |
| 762 |    247.482463 |     66.100486 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 763 |    597.011051 |    460.615379 | NA                                                                                                                                                                    |
| 764 |    978.199485 |    516.427496 | Darius Nau                                                                                                                                                            |
| 765 |    784.202554 |    720.363876 | Kamil S. Jaron                                                                                                                                                        |
| 766 |    346.205496 |    514.283879 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 767 |    291.766038 |    329.615284 | Gareth Monger                                                                                                                                                         |
| 768 |    373.115659 |    713.913719 | Gordon E. Robertson                                                                                                                                                   |
| 769 |     16.852593 |    345.754749 | Zimices                                                                                                                                                               |
| 770 |    967.985598 |    285.594932 | Scott Hartman                                                                                                                                                         |
| 771 |   1002.217629 |     51.311855 | Smokeybjb                                                                                                                                                             |
| 772 |    877.131930 |    189.695386 | T. Michael Keesey                                                                                                                                                     |
| 773 |    689.854860 |    628.062039 | T. Michael Keesey                                                                                                                                                     |
| 774 |    996.222344 |    726.537595 | Mathilde Cordellier                                                                                                                                                   |
| 775 |    218.577767 |    366.572322 | Zimices                                                                                                                                                               |
| 776 |    277.611558 |     84.830027 | NASA                                                                                                                                                                  |
| 777 |    300.246085 |    637.071929 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 778 |    171.596274 |    397.947329 | Zimices                                                                                                                                                               |
| 779 |    498.802822 |    538.251156 | Zimices                                                                                                                                                               |
| 780 |    851.737323 |    542.183225 | Matt Crook                                                                                                                                                            |
| 781 |     67.335487 |    658.936110 | Beth Reinke                                                                                                                                                           |
| 782 |    152.197336 |    584.291838 | Margot Michaud                                                                                                                                                        |
| 783 |     88.318075 |    683.108888 | Margot Michaud                                                                                                                                                        |
| 784 |     57.103884 |    464.562415 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 785 |   1005.238614 |    299.739019 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                 |
| 786 |    946.170146 |    718.234960 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 787 |    471.774707 |    402.017594 | Matt Martyniuk                                                                                                                                                        |
| 788 |    355.339189 |    479.642971 | Stuart Humphries                                                                                                                                                      |
| 789 |    202.317162 |    181.473439 | Zimices                                                                                                                                                               |
| 790 |    264.946240 |    651.632193 | Margot Michaud                                                                                                                                                        |
| 791 |    413.966311 |    601.390232 | Iain Reid                                                                                                                                                             |
| 792 |    861.505661 |    150.359433 | Matt Martyniuk                                                                                                                                                        |
| 793 |    850.033979 |    770.595886 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 794 |    720.151457 |    362.421623 | Matt Crook                                                                                                                                                            |
| 795 |    530.347905 |    154.710694 | Steven Coombs                                                                                                                                                         |
| 796 |     53.404422 |    385.022461 | Zimices                                                                                                                                                               |
| 797 |    477.578416 |    193.191868 | Gareth Monger                                                                                                                                                         |
| 798 |    438.445820 |    351.382800 | Tauana J. Cunha                                                                                                                                                       |
| 799 |    644.628195 |    364.442461 | NA                                                                                                                                                                    |
| 800 |     37.940628 |      9.433136 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 801 |    294.211000 |    513.737070 | Steven Traver                                                                                                                                                         |
| 802 |    854.140957 |    576.854005 | Steven Traver                                                                                                                                                         |
| 803 |    622.712729 |    639.289561 | Alexandre Vong                                                                                                                                                        |
| 804 |    638.290138 |    492.441801 | Felix Vaux                                                                                                                                                            |
| 805 |    373.741302 |    517.256509 | Gopal Murali                                                                                                                                                          |
| 806 |    513.052587 |    258.258789 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 807 |    913.797643 |    734.732227 | Lukasiniho                                                                                                                                                            |
| 808 |    971.141896 |    496.911468 | Steven Traver                                                                                                                                                         |
| 809 |    287.497956 |    432.633502 | G. M. Woodward                                                                                                                                                        |
| 810 |    182.985389 |    784.616906 | Margot Michaud                                                                                                                                                        |
| 811 |    445.976175 |    124.345538 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 812 |    644.176853 |    710.067936 | Margot Michaud                                                                                                                                                        |
| 813 |    366.097187 |    684.486412 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 814 |    736.272142 |    224.371210 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 815 |     90.363476 |    490.331321 | Matt Crook                                                                                                                                                            |
| 816 |     21.376076 |    625.200185 | Ferran Sayol                                                                                                                                                          |
| 817 |    581.843815 |    614.018442 | T. Michael Keesey                                                                                                                                                     |
| 818 |    858.635538 |    229.982970 | Margot Michaud                                                                                                                                                        |
| 819 |    572.707779 |    243.096982 | Mathieu Pélissié                                                                                                                                                      |
| 820 |    559.851145 |    209.997281 | Anthony Caravaggi                                                                                                                                                     |
| 821 |    522.335019 |    130.602935 |                                                                                                                                                                       |
| 822 |   1009.589058 |    363.708390 | Collin Gross                                                                                                                                                          |
| 823 |    523.605410 |     10.434023 | Jagged Fang Designs                                                                                                                                                   |
| 824 |    172.962075 |    566.198741 | Mathilde Cordellier                                                                                                                                                   |
| 825 |    632.505858 |    715.158436 | Steven Traver                                                                                                                                                         |
| 826 |    804.837461 |    351.546731 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                  |
| 827 |    349.080198 |    358.273715 | Sarah Werning                                                                                                                                                         |
| 828 |    895.691777 |    194.458519 | T. Michael Keesey                                                                                                                                                     |
| 829 |    646.743322 |     29.731282 | Gareth Monger                                                                                                                                                         |
| 830 |     14.006830 |    325.366856 | Scott Hartman                                                                                                                                                         |
| 831 |    186.283451 |    214.641838 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 832 |    710.647345 |    337.875453 | Scott Hartman                                                                                                                                                         |
| 833 |    495.773763 |    403.344862 | Matt Crook                                                                                                                                                            |
| 834 |   1004.384508 |    792.887233 | Sarah Werning                                                                                                                                                         |
| 835 |    309.337084 |    590.390306 | Jessica Rick                                                                                                                                                          |
| 836 |    100.462175 |     93.603935 | Margot Michaud                                                                                                                                                        |
| 837 |    523.684128 |    526.309138 | Steven Traver                                                                                                                                                         |
| 838 |    257.058842 |    337.371423 | Matt Crook                                                                                                                                                            |
| 839 |    982.367617 |    727.035619 | Melissa Broussard                                                                                                                                                     |
| 840 |   1017.883529 |    759.862986 | Gareth Monger                                                                                                                                                         |
| 841 |    639.635640 |    657.778137 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 842 |    165.668895 |    446.222889 | Anthony Caravaggi                                                                                                                                                     |
| 843 |    232.456649 |    109.657548 | Mathew Wedel                                                                                                                                                          |
| 844 |    605.500632 |    229.962500 | Liftarn                                                                                                                                                               |
| 845 |     57.906143 |    125.070920 | Mattia Menchetti                                                                                                                                                      |
| 846 |    328.747134 |    454.828336 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 847 |    786.754381 |    355.867138 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 848 |    127.705349 |    647.730878 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 849 |    575.401535 |    360.798739 | Gareth Monger                                                                                                                                                         |
| 850 |   1008.291274 |     87.201260 | CNZdenek                                                                                                                                                              |
| 851 |    218.658389 |    578.300995 | Christoph Schomburg                                                                                                                                                   |
| 852 |    162.571764 |    290.740772 | Birgit Lang                                                                                                                                                           |
| 853 |    817.866032 |    226.526457 | Michelle Site                                                                                                                                                         |
| 854 |    192.983664 |     12.810773 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 855 |    762.354243 |    258.484312 | Margot Michaud                                                                                                                                                        |
| 856 |    378.325383 |    314.511793 | Kamil S. Jaron                                                                                                                                                        |
| 857 |    762.611188 |    794.482101 | Matt Crook                                                                                                                                                            |
| 858 |    120.848662 |    208.616618 | Tasman Dixon                                                                                                                                                          |
| 859 |    691.811484 |     37.798075 | Jagged Fang Designs                                                                                                                                                   |
| 860 |    846.708471 |    487.208480 | Bryan Carstens                                                                                                                                                        |
| 861 |    970.116859 |    594.388577 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 862 |    778.601350 |    322.710418 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 863 |    364.728284 |    142.261454 | NA                                                                                                                                                                    |
| 864 |    666.371739 |    731.058955 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 865 |    488.802832 |    238.118074 | Zimices                                                                                                                                                               |
| 866 |    405.901963 |    468.897696 | Manabu Bessho-Uehara                                                                                                                                                  |
| 867 |    934.857182 |    727.226163 | Curtis Clark and T. Michael Keesey                                                                                                                                    |
| 868 |    985.919922 |    666.478088 | Ferran Sayol                                                                                                                                                          |
| 869 |    718.237312 |    387.190185 | Jagged Fang Designs                                                                                                                                                   |
| 870 |    678.026265 |    671.060177 | Javier Luque & Sarah Gerken                                                                                                                                           |
| 871 |    109.359306 |    702.604909 | Markus A. Grohme                                                                                                                                                      |
| 872 |    983.209876 |     69.521307 | NA                                                                                                                                                                    |
| 873 |    224.467606 |    323.671221 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 874 |    338.012893 |    641.782346 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 875 |    518.567334 |    228.690481 | Matt Crook                                                                                                                                                            |
| 876 |    984.521235 |    291.093577 | Zimices                                                                                                                                                               |
| 877 |    879.643370 |    134.967771 | Beth Reinke                                                                                                                                                           |
| 878 |    114.509706 |    626.642027 | Ferran Sayol                                                                                                                                                          |
| 879 |    876.318978 |    541.075806 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 880 |    253.720602 |    301.327110 | NA                                                                                                                                                                    |
| 881 |    743.934006 |    773.136079 | Tracy A. Heath                                                                                                                                                        |
| 882 |    864.666716 |    215.562838 | T. Michael Keesey                                                                                                                                                     |
| 883 |    880.547167 |    400.771357 | Scott Hartman                                                                                                                                                         |
| 884 |     78.513678 |    576.289344 | NA                                                                                                                                                                    |
| 885 |    591.314609 |    254.080992 | Tasman Dixon                                                                                                                                                          |
| 886 |    778.909412 |    577.675789 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 887 |    657.721032 |    360.757584 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 888 |     17.085228 |    136.185650 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 889 |    766.187394 |    405.755077 | Dean Schnabel                                                                                                                                                         |
| 890 |    240.586488 |    344.485040 | Scott Hartman                                                                                                                                                         |
| 891 |    686.776261 |    475.549318 | Nobu Tamura                                                                                                                                                           |
| 892 |    187.994364 |    281.207814 | Melissa Broussard                                                                                                                                                     |
| 893 |    516.636277 |    119.816804 | Kai R. Caspar                                                                                                                                                         |
| 894 |     30.533545 |    416.363256 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 895 |    146.869803 |    390.762266 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 896 |    671.508455 |    759.072077 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 897 |    250.335755 |    501.910520 | Zimices                                                                                                                                                               |
| 898 |    532.257065 |    337.071936 | Matt Crook                                                                                                                                                            |
| 899 |    411.748684 |    676.949943 | Gareth Monger                                                                                                                                                         |
| 900 |    203.220592 |    573.440777 | Nicolas Mongiardino Koch                                                                                                                                              |
| 901 |    553.838907 |    111.674068 | Matt Crook                                                                                                                                                            |
| 902 |    142.154074 |    558.471929 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 903 |    288.012211 |    308.562000 | (after Spotila 2004)                                                                                                                                                  |

    #> Your tweet has been posted!
