
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

Iain Reid, Katie S. Collins, Markus A. Grohme, T. Michael Keesey, Matt
Crook, Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, FunkMonk, Melissa Broussard, Francisco Gascó
(modified by Michael P. Taylor), Tracy A. Heath, Steven Traver, Zimices,
Chase Brownstein, Birgit Lang, Jebulon (vectorized by T. Michael
Keesey), Robert Gay, modifed from Olegivvit, Nobu Tamura and T. Michael
Keesey, Lauren Sumner-Rooney, Gareth Monger, Jaime Headden, Jon Hill
(Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Ferran
Sayol, Javier Luque, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Jack Mayer Wood,
Gabriela Palomo-Munoz, Scott Hartman, Ignacio Contreras, Tasman Dixon,
Jagged Fang Designs, Obsidian Soul (vectorized by T. Michael Keesey),
Mathieu Pélissié, Collin Gross, Carlos Cano-Barbacil, Andy Wilson, Danny
Cicchetti (vectorized by T. Michael Keesey), Martin R. Smith, after
Skovsted et al 2015, Michael “FunkMonk” B. H. (vectorized by T. Michael
Keesey), Felix Vaux, Joanna Wolfe, Dmitry Bogdanov, Smokeybjb, M
Kolmann, Nobu Tamura (vectorized by T. Michael Keesey), Dmitry Bogdanov
(vectorized by T. Michael Keesey), Andrew Farke and Joseph Sertich,
Ludwik Gąsiorowski, Air Kebir NRG, Caleb M. Brown, Darius Nau, Manabu
Sakamoto, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), John Curtis
(vectorized by T. Michael Keesey), Caleb M. Gordon, Dr. Thomas G.
Barnes, USFWS, Maija Karala, Charles R. Knight (vectorized by T. Michael
Keesey), Pete Buchholz, Margot Michaud, Kristina Gagalova, Noah
Schlottman, photo by Hans De Blauwe, Ellen Edmonson and Hugh Chrisp
(vectorized by T. Michael Keesey), Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Lafage,
Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Jose Carlos
Arenas-Monroy, Xavier Giroux-Bougard, NOAA (vectorized by T. Michael
Keesey), Christoph Schomburg, Taro Maeda, Sean McCann, T. Michael Keesey
(photo by J. M. Garg), Beth Reinke, Campbell Fleming, Dave Angelini,
Tess Linden, Mason McNair, Xvazquez (vectorized by William Gearty),
Warren H (photography), T. Michael Keesey (vectorization), Amanda
Katzer, Armin Reindl, Yan Wong, Kai R. Caspar, Stuart Humphries, Kamil
S. Jaron, terngirl, RS, Lisa Byrne, Ingo Braasch, Michelle Site, Henry
Lydecker, Eyal Bartov, Baheerathan Murugavel, annaleeblysse, Maxime
Dahirel, Dmitry Bogdanov, vectorized by Zimices, xgirouxb, Jonathan
Wells, C. Camilo Julián-Caballero, Sarefo (vectorized by T. Michael
Keesey), Berivan Temiz, Kanchi Nanjo, Nobu Tamura, vectorized by
Zimices, Mattia Menchetti, Roberto Díaz Sibaja, Lukasiniho, S.Martini,
L. Shyamal, Cathy, Martin R. Smith, Trond R. Oskars, Margret Flinsch,
vectorized by Zimices, Tony Ayling (vectorized by T. Michael Keesey),
Mette Aumala, Chris huh, Mathew Wedel, George Edward Lodge, Chris A.
Hamilton, david maas / dave hone, Dianne Bray / Museum Victoria
(vectorized by T. Michael Keesey), Emily Willoughby, Becky Barnes,
Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Terpsichores, Robert Gay, Mark Hannaford (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Brad
McFeeters (vectorized by T. Michael Keesey), Michael Ströck (vectorized
by T. Michael Keesey), Roderic Page and Lois Page, B. Duygu Özpolat,
Mathieu Basille, Didier Descouens (vectorized by T. Michael Keesey),
Chloé Schmidt, Julia B McHugh, Fernando Campos De Domenico, Marie
Russell, Alexandre Vong, Matt Martyniuk, Milton Tan, Dean Schnabel, Noah
Schlottman, Marie-Aimée Allard, Andreas Trepte (vectorized by T. Michael
Keesey), Fernando Carezzano, Chuanixn Yu, Alexandra van der Geer,
Stanton F. Fink (vectorized by T. Michael Keesey), David Orr, V. Deepak,
Ghedo (vectorized by T. Michael Keesey), Noah Schlottman, photo from
National Science Foundation - Turbellarian Taxonomic Database, ДиБгд
(vectorized by T. Michael Keesey), Karl Ragnar Gjertsen (vectorized by
T. Michael Keesey), Benjamin Monod-Broca, Manabu Bessho-Uehara, Noah
Schlottman, photo by Carlos Sánchez-Ortiz, Apokryltaros (vectorized by
T. Michael Keesey), Jim Bendon (photography) and T. Michael Keesey
(vectorization), Matthew Hooge (vectorized by T. Michael Keesey),
Anilocra (vectorization by Yan Wong), Thea Boodhoo (photograph) and T.
Michael Keesey (vectorization), Jimmy Bernot, CNZdenek, Sarah Werning,
Matt Hayes, M. A. Broussard, Original drawing by Antonov, vectorized by
Roberto Díaz Sibaja, Bennet McComish, photo by Hans Hillewaert, Lisa M.
“Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Alex Slavenko, Jiekun He, Crystal Maier, Steven Coombs,
Alexander Schmidt-Lebuhn, Christian A. Masnaghetti, Young and Zhao
(1972:figure 4), modified by Michael P. Taylor, Louis Ranjard, Lily
Hughes, Cesar Julian, Leon P. A. M. Claessens, Patrick M. O’Connor,
David M. Unwin, Andrew A. Farke, T. Michael Keesey (vectorization) and
Nadiatalent (photography), Leann Biancani, photo by Kenneth Clifton,
Shyamal, Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Bill Bouton (source photo) & T. Michael
Keesey (vectorization), Steven Coombs (vectorized by T. Michael Keesey),
Elizabeth Parker, John Conway, FJDegrange, Matt Martyniuk (modified by
Serenchia), Kent Elson Sorgon, Claus Rebler, Lani Mohan, T. Tischler,
Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, DW Bapst (modified from Bates et al., 2005), Sharon
Wegner-Larsen, M. Garfield & K. Anderson (modified by T. Michael
Keesey), Robert Bruce Horsfall, vectorized by Zimices, Robert Bruce
Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the
Western Hemisphere”, Keith Murdock (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Rebecca Groom, Joris van der Ham
(vectorized by T. Michael Keesey), Matt Wilkins, Tauana J. Cunha, Tim H.
Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael
Keesey), FunkMonk (Michael B. H.), Jean-Raphaël Guillaumin (photography)
and T. Michael Keesey (vectorization), Mihai Dragos (vectorized by T.
Michael Keesey), Sergio A. Muñoz-Gómez, DW Bapst, modified from Ishitani
et al. 2016, T. Michael Keesey (after Mivart), George Edward Lodge
(modified by T. Michael Keesey), Anthony Caravaggi,
Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, New York Zoological Society, Josefine
Bohr Brask, Inessa Voet, Smokeybjb (vectorized by T. Michael Keesey), T.
Michael Keesey (after Masteraah), Ghedoghedo, Ernst Haeckel (vectorized
by T. Michael Keesey), M Hutchinson, Mathilde Cordellier, Danielle Alba,
Yan Wong from illustration by Charles Orbigny, Birgit Lang, based on a
photo by D. Sikes, Davidson Sodré, T. Michael Keesey (after Joseph
Wolf), DW Bapst (modified from Mitchell 1990), Erika Schumacher, Birgit
Lang; based on a drawing by C.L. Koch, \[unknown\], Original drawing by
Nobu Tamura, vectorized by Roberto Díaz Sibaja, Harold N Eyster, Florian
Pfaff, Tony Ayling, Darren Naish (vectorized by T. Michael Keesey), Yan
Wong from wikipedia drawing (PD: Pearson Scott Foresman), Frank Förster
(based on a picture by Hans Hillewaert), Ghedoghedo (vectorized by T.
Michael Keesey), Nina Skinner, Mali’o Kodis, image from the Smithsonian
Institution, Evan Swigart (photography) and T. Michael Keesey
(vectorization), Pearson Scott Foresman (vectorized by T. Michael
Keesey), Thibaut Brunet, Lee Harding (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Michael Scroggie, from original
photograph by Gary M. Stolz, USFWS (original photograph in public
domain)., Renato de Carvalho Ferreira, Isaure Scavezzoni, Noah
Schlottman, photo by Museum of Geology, University of Tartu, Mali’o
Kodis, photograph by John Slapcinsky, Noah Schlottman, photo by Martin
V. Sørensen, Tim Bertelink (modified by T. Michael Keesey), Meyers
Konversations-Lexikon 1897 (vectorized: Yan Wong), Jake Warner, Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Ramona J Heim, Francisco Manuel Blanco (vectorized by
T. Michael Keesey), wsnaccad, Jaime Headden (vectorized by T. Michael
Keesey), Maxwell Lefroy (vectorized by T. Michael Keesey), Chris Hay,
Michael Scroggie, Robbie N. Cada (vectorized by T. Michael Keesey),
Almandine (vectorized by T. Michael Keesey), Arthur S. Brum, Steven
Haddock • Jellywatch.org, Oscar Sanisidro, T. Michael Keesey (from a
photo by Maximilian Paradiz), Gabriele Midolo, Matt Martyniuk (modified
by T. Michael Keesey), Juan Carlos Jerí, James R. Spotila and Ray
Chatterji, Antonov (vectorized by T. Michael Keesey), Dmitry Bogdanov
and FunkMonk (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    869.650584 |    466.298475 | Iain Reid                                                                                                                                                             |
|   2 |    688.230748 |    642.136058 | Katie S. Collins                                                                                                                                                      |
|   3 |    478.185226 |    211.399714 | Markus A. Grohme                                                                                                                                                      |
|   4 |    878.365380 |    734.233204 | T. Michael Keesey                                                                                                                                                     |
|   5 |    566.692965 |    106.634765 | T. Michael Keesey                                                                                                                                                     |
|   6 |    689.945671 |    391.751253 | Matt Crook                                                                                                                                                            |
|   7 |    400.091798 |    750.906319 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
|   8 |    618.670096 |    282.312728 | FunkMonk                                                                                                                                                              |
|   9 |    938.455115 |    653.940912 | Melissa Broussard                                                                                                                                                     |
|  10 |    248.712781 |    331.493884 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
|  11 |    536.870781 |    529.308040 | Tracy A. Heath                                                                                                                                                        |
|  12 |    295.868942 |     39.088769 | Steven Traver                                                                                                                                                         |
|  13 |    368.722933 |    203.464868 | Matt Crook                                                                                                                                                            |
|  14 |    243.579197 |    726.306958 | Iain Reid                                                                                                                                                             |
|  15 |     72.631439 |    318.684195 | Zimices                                                                                                                                                               |
|  16 |    162.527569 |    426.101980 | Chase Brownstein                                                                                                                                                      |
|  17 |    897.486205 |    104.594889 | Birgit Lang                                                                                                                                                           |
|  18 |    814.868773 |    641.528620 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
|  19 |    392.808939 |    603.911364 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
|  20 |    313.732524 |    113.667318 | T. Michael Keesey                                                                                                                                                     |
|  21 |    295.346441 |    460.527376 | Matt Crook                                                                                                                                                            |
|  22 |    926.172598 |    300.458527 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
|  23 |    808.895277 |    254.421425 | Steven Traver                                                                                                                                                         |
|  24 |    713.083314 |     71.302749 | Lauren Sumner-Rooney                                                                                                                                                  |
|  25 |    534.380204 |    664.497559 | Matt Crook                                                                                                                                                            |
|  26 |    114.903341 |    147.728013 | Gareth Monger                                                                                                                                                         |
|  27 |    890.609465 |    535.457663 | NA                                                                                                                                                                    |
|  28 |    856.404326 |    379.936470 | Jaime Headden                                                                                                                                                         |
|  29 |    498.388622 |    374.589079 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
|  30 |     62.961427 |    459.764175 | Gareth Monger                                                                                                                                                         |
|  31 |    639.482578 |    179.331335 | Ferran Sayol                                                                                                                                                          |
|  32 |    170.450892 |     48.667128 | Javier Luque                                                                                                                                                          |
|  33 |    461.074757 |     64.623081 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  34 |    373.157934 |    285.909918 | Jack Mayer Wood                                                                                                                                                       |
|  35 |    800.011965 |    769.563378 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  36 |    287.778844 |    578.081966 | Matt Crook                                                                                                                                                            |
|  37 |    147.731431 |    540.092640 | Gareth Monger                                                                                                                                                         |
|  38 |    100.666409 |    639.569192 | Scott Hartman                                                                                                                                                         |
|  39 |    752.378230 |    546.749106 | Ignacio Contreras                                                                                                                                                     |
|  40 |    893.862130 |    198.111483 | Iain Reid                                                                                                                                                             |
|  41 |     91.883285 |    730.740261 | Tasman Dixon                                                                                                                                                          |
|  42 |    856.177109 |     30.016478 | Jagged Fang Designs                                                                                                                                                   |
|  43 |    710.984769 |    503.414320 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  44 |    251.688767 |    235.026575 | Ferran Sayol                                                                                                                                                          |
|  45 |    974.110641 |    414.142394 | Mathieu Pélissié                                                                                                                                                      |
|  46 |    369.891922 |    481.595382 | Ignacio Contreras                                                                                                                                                     |
|  47 |    800.897153 |    432.218013 | Collin Gross                                                                                                                                                          |
|  48 |    647.941522 |    760.824026 | Carlos Cano-Barbacil                                                                                                                                                  |
|  49 |    408.147687 |    339.944061 | Andy Wilson                                                                                                                                                           |
|  50 |    250.324760 |    645.856709 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
|  51 |    549.251155 |    400.869360 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
|  52 |    696.682136 |    259.107369 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
|  53 |    494.126176 |    280.302306 | Zimices                                                                                                                                                               |
|  54 |    761.844065 |    116.233749 | Matt Crook                                                                                                                                                            |
|  55 |    365.592214 |    689.317333 | Felix Vaux                                                                                                                                                            |
|  56 |    178.460879 |    468.094844 | Tasman Dixon                                                                                                                                                          |
|  57 |    907.774932 |    156.565246 | Joanna Wolfe                                                                                                                                                          |
|  58 |    112.925868 |    236.035208 | Zimices                                                                                                                                                               |
|  59 |    562.395638 |    752.173905 | Dmitry Bogdanov                                                                                                                                                       |
|  60 |    856.030075 |    588.310790 | Smokeybjb                                                                                                                                                             |
|  61 |    273.868905 |    396.295162 | M Kolmann                                                                                                                                                             |
|  62 |    958.864255 |    550.127793 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  63 |    567.175065 |     25.188949 | Zimices                                                                                                                                                               |
|  64 |    720.161840 |    222.823997 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  65 |    142.588577 |    589.092320 | Andrew Farke and Joseph Sertich                                                                                                                                       |
|  66 |     37.001860 |    116.981879 | Ludwik Gąsiorowski                                                                                                                                                    |
|  67 |    961.038324 |    209.029693 | Matt Crook                                                                                                                                                            |
|  68 |    516.105029 |    140.722708 | Air Kebir NRG                                                                                                                                                         |
|  69 |    782.372950 |    723.905721 | Caleb M. Brown                                                                                                                                                        |
|  70 |    171.558608 |    374.573750 | Darius Nau                                                                                                                                                            |
|  71 |    773.650611 |    471.664448 | Manabu Sakamoto                                                                                                                                                       |
|  72 |    217.819320 |     12.522360 | Zimices                                                                                                                                                               |
|  73 |    953.278229 |    483.106464 | Smokeybjb                                                                                                                                                             |
|  74 |    832.780347 |    325.375523 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  75 |    960.925982 |    103.407949 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  76 |    913.455901 |    406.053990 | Smokeybjb                                                                                                                                                             |
|  77 |    200.577752 |    140.465007 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
|  78 |    578.138498 |    385.106605 | Caleb M. Gordon                                                                                                                                                       |
|  79 |    762.261910 |    403.994042 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
|  80 |    614.356947 |     48.791542 | Maija Karala                                                                                                                                                          |
|  81 |    318.146042 |    161.128327 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
|  82 |     26.076479 |    696.927297 | Chase Brownstein                                                                                                                                                      |
|  83 |    163.666552 |     86.166229 | Pete Buchholz                                                                                                                                                         |
|  84 |   1008.338265 |    704.992751 | Steven Traver                                                                                                                                                         |
|  85 |    367.153798 |    713.389169 | Margot Michaud                                                                                                                                                        |
|  86 |     70.106452 |    542.710726 | Steven Traver                                                                                                                                                         |
|  87 |     57.409143 |    522.455715 | Gareth Monger                                                                                                                                                         |
|  88 |    972.890368 |    727.868053 | Kristina Gagalova                                                                                                                                                     |
|  89 |    186.951497 |    733.556264 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                              |
|  90 |    819.409465 |    751.727784 | Scott Hartman                                                                                                                                                         |
|  91 |    187.067960 |     87.285941 | T. Michael Keesey                                                                                                                                                     |
|  92 |    366.405168 |    652.317764 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
|  93 |    491.245917 |     38.273189 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  94 |    920.760072 |    685.088359 | Jagged Fang Designs                                                                                                                                                   |
|  95 |    870.235511 |    309.654742 | Zimices                                                                                                                                                               |
|  96 |    229.860777 |    428.521274 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  97 |    758.571512 |    170.320106 | Scott Hartman                                                                                                                                                         |
|  98 |    530.739541 |     69.128006 | NA                                                                                                                                                                    |
|  99 |    665.947296 |    517.195867 | Lafage                                                                                                                                                                |
| 100 |    280.824570 |    702.818205 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                 |
| 101 |     62.703824 |    706.245845 | Margot Michaud                                                                                                                                                        |
| 102 |    907.385336 |    630.962852 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 103 |    638.373953 |    112.857489 | Xavier Giroux-Bougard                                                                                                                                                 |
| 104 |   1006.529809 |    772.554441 | Jaime Headden                                                                                                                                                         |
| 105 |    200.535826 |    779.726836 | Matt Crook                                                                                                                                                            |
| 106 |    433.390968 |    606.926062 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 107 |    566.184212 |    222.696399 | Scott Hartman                                                                                                                                                         |
| 108 |    896.894730 |    654.308985 | Christoph Schomburg                                                                                                                                                   |
| 109 |    886.342228 |    430.389443 | Margot Michaud                                                                                                                                                        |
| 110 |     53.506556 |    586.214250 | Taro Maeda                                                                                                                                                            |
| 111 |    947.159901 |    751.841091 | NA                                                                                                                                                                    |
| 112 |    924.302330 |    775.092293 | Jagged Fang Designs                                                                                                                                                   |
| 113 |    626.049497 |     96.280827 | Tracy A. Heath                                                                                                                                                        |
| 114 |   1005.966623 |    216.727155 | Zimices                                                                                                                                                               |
| 115 |    433.023214 |    570.230960 | Ferran Sayol                                                                                                                                                          |
| 116 |    141.437430 |    185.752801 | Margot Michaud                                                                                                                                                        |
| 117 |    444.216832 |    724.698899 | NA                                                                                                                                                                    |
| 118 |    428.628784 |    449.623603 | Sean McCann                                                                                                                                                           |
| 119 |    123.754362 |    783.531898 | Markus A. Grohme                                                                                                                                                      |
| 120 |    146.778698 |    328.069616 | Margot Michaud                                                                                                                                                        |
| 121 |    114.185558 |     79.212497 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 122 |    647.835471 |    648.663732 | Beth Reinke                                                                                                                                                           |
| 123 |    611.565489 |    451.665098 | Zimices                                                                                                                                                               |
| 124 |    985.855085 |    165.819505 | Matt Crook                                                                                                                                                            |
| 125 |    374.827952 |     29.461729 | Campbell Fleming                                                                                                                                                      |
| 126 |    268.957127 |    281.620690 | Dave Angelini                                                                                                                                                         |
| 127 |    880.057085 |    444.142525 | Tess Linden                                                                                                                                                           |
| 128 |    390.364894 |     50.167890 | Mason McNair                                                                                                                                                          |
| 129 |     21.841050 |    399.404095 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 130 |    392.855714 |    411.620077 | Joanna Wolfe                                                                                                                                                          |
| 131 |    904.165767 |     48.140514 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 132 |     91.771978 |     24.393894 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 133 |    817.140606 |    478.895338 | Gareth Monger                                                                                                                                                         |
| 134 |     71.995486 |    413.660847 | Mason McNair                                                                                                                                                          |
| 135 |    378.266458 |    223.113534 | Matt Crook                                                                                                                                                            |
| 136 |    271.270731 |    169.423075 | Birgit Lang                                                                                                                                                           |
| 137 |    360.608838 |    358.448124 | Amanda Katzer                                                                                                                                                         |
| 138 |    561.190945 |    554.638742 | Matt Crook                                                                                                                                                            |
| 139 |    422.212587 |    783.516503 | Armin Reindl                                                                                                                                                          |
| 140 |    878.534269 |    529.459442 | Yan Wong                                                                                                                                                              |
| 141 |    595.963444 |    307.119400 | Kai R. Caspar                                                                                                                                                         |
| 142 |    779.151865 |    515.971168 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 143 |    466.736101 |    669.703442 | Chase Brownstein                                                                                                                                                      |
| 144 |    704.318894 |    364.365254 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 145 |    401.177810 |    193.216225 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 146 |    609.479151 |    332.651138 | Caleb M. Brown                                                                                                                                                        |
| 147 |    664.465824 |    712.031882 | Markus A. Grohme                                                                                                                                                      |
| 148 |    522.240547 |    226.259348 | Stuart Humphries                                                                                                                                                      |
| 149 |    307.800321 |    670.209332 | Kamil S. Jaron                                                                                                                                                        |
| 150 |     88.010981 |    598.002136 | Matt Crook                                                                                                                                                            |
| 151 |    112.038893 |    283.961468 | T. Michael Keesey                                                                                                                                                     |
| 152 |     22.206468 |    498.359609 | Ferran Sayol                                                                                                                                                          |
| 153 |    411.909405 |    667.045313 | terngirl                                                                                                                                                              |
| 154 |    721.672030 |    705.819770 | Andy Wilson                                                                                                                                                           |
| 155 |    718.315223 |    182.185721 | RS                                                                                                                                                                    |
| 156 |    219.394533 |    688.759025 | Lisa Byrne                                                                                                                                                            |
| 157 |    218.459907 |    515.668356 | Ingo Braasch                                                                                                                                                          |
| 158 |    436.057870 |    231.075377 | Steven Traver                                                                                                                                                         |
| 159 |    904.373426 |    421.550443 | Ferran Sayol                                                                                                                                                          |
| 160 |    409.481354 |    530.011584 | Tracy A. Heath                                                                                                                                                        |
| 161 |    739.469480 |    248.531508 | Michelle Site                                                                                                                                                         |
| 162 |     56.004472 |    746.953485 | Kamil S. Jaron                                                                                                                                                        |
| 163 |     33.441781 |    378.395627 | Zimices                                                                                                                                                               |
| 164 |     80.500492 |    445.036921 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 165 |    468.486735 |    171.008297 | Matt Crook                                                                                                                                                            |
| 166 |     31.819909 |     18.674976 | Margot Michaud                                                                                                                                                        |
| 167 |    667.213203 |     17.589583 | Matt Crook                                                                                                                                                            |
| 168 |    740.598971 |    387.253519 | Henry Lydecker                                                                                                                                                        |
| 169 |    163.394695 |     97.916611 | Eyal Bartov                                                                                                                                                           |
| 170 |    417.555952 |    418.173004 | Jack Mayer Wood                                                                                                                                                       |
| 171 |    365.803807 |    168.584612 | Matt Crook                                                                                                                                                            |
| 172 |    335.564899 |      6.612120 | Zimices                                                                                                                                                               |
| 173 |    836.934990 |    219.757323 | Zimices                                                                                                                                                               |
| 174 |     49.745586 |    769.990497 | Baheerathan Murugavel                                                                                                                                                 |
| 175 |    779.998475 |     43.242365 | Zimices                                                                                                                                                               |
| 176 |    757.653554 |    613.133640 | Andy Wilson                                                                                                                                                           |
| 177 |    869.968358 |    264.091212 | annaleeblysse                                                                                                                                                         |
| 178 |    816.894892 |    114.738982 | Maxime Dahirel                                                                                                                                                        |
| 179 |    756.508215 |    281.424284 | Jagged Fang Designs                                                                                                                                                   |
| 180 |    967.204047 |    354.010106 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 181 |    194.575504 |    200.497934 | xgirouxb                                                                                                                                                              |
| 182 |    810.461411 |    172.638616 | Jonathan Wells                                                                                                                                                        |
| 183 |    761.789090 |    735.840683 | Mathieu Pélissié                                                                                                                                                      |
| 184 |    382.022709 |     63.294467 | C. Camilo Julián-Caballero                                                                                                                                            |
| 185 |    455.923620 |    449.144863 | T. Michael Keesey                                                                                                                                                     |
| 186 |    298.297090 |    779.065989 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 187 |    371.281932 |     56.587328 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 188 |    264.580566 |    305.292728 | Berivan Temiz                                                                                                                                                         |
| 189 |   1005.246044 |    114.779836 | Scott Hartman                                                                                                                                                         |
| 190 |    663.524545 |    131.340822 | Ferran Sayol                                                                                                                                                          |
| 191 |    457.005209 |    625.113773 | Zimices                                                                                                                                                               |
| 192 |    450.984490 |    645.062540 | Joanna Wolfe                                                                                                                                                          |
| 193 |    468.663034 |    119.021467 | Ingo Braasch                                                                                                                                                          |
| 194 |    182.794192 |    512.429349 | Margot Michaud                                                                                                                                                        |
| 195 |    590.516453 |     70.333552 | Matt Crook                                                                                                                                                            |
| 196 |    407.713777 |    509.388565 | Matt Crook                                                                                                                                                            |
| 197 |    976.488035 |      4.847006 | Zimices                                                                                                                                                               |
| 198 |    598.621417 |    149.720440 | Kanchi Nanjo                                                                                                                                                          |
| 199 |    575.815860 |    454.402721 | Matt Crook                                                                                                                                                            |
| 200 |    539.839381 |    728.819616 | Andy Wilson                                                                                                                                                           |
| 201 |    338.008928 |    328.745813 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 202 |    627.449756 |    390.334314 | Zimices                                                                                                                                                               |
| 203 |    707.609004 |    724.548340 | Matt Crook                                                                                                                                                            |
| 204 |    959.382031 |    509.404798 | Gareth Monger                                                                                                                                                         |
| 205 |    146.696298 |    203.550619 | Matt Crook                                                                                                                                                            |
| 206 |     94.609514 |    657.480297 | Mattia Menchetti                                                                                                                                                      |
| 207 |    397.790675 |    230.118366 | Zimices                                                                                                                                                               |
| 208 |    289.889526 |    237.230019 | Roberto Díaz Sibaja                                                                                                                                                   |
| 209 |    891.296482 |    334.279113 | NA                                                                                                                                                                    |
| 210 |    999.423005 |    461.277626 | Margot Michaud                                                                                                                                                        |
| 211 |    784.311128 |    667.300670 | Steven Traver                                                                                                                                                         |
| 212 |    710.532603 |    744.819312 | Lukasiniho                                                                                                                                                            |
| 213 |    459.699779 |    579.955886 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 214 |    644.337526 |    201.129099 | Gareth Monger                                                                                                                                                         |
| 215 |    845.221104 |     97.413367 | Tasman Dixon                                                                                                                                                          |
| 216 |    719.030564 |    785.344324 | Matt Crook                                                                                                                                                            |
| 217 |    466.770990 |    705.442151 | Roberto Díaz Sibaja                                                                                                                                                   |
| 218 |    601.640013 |    238.745690 | NA                                                                                                                                                                    |
| 219 |    778.419990 |     53.464525 | Katie S. Collins                                                                                                                                                      |
| 220 |    430.720655 |    556.295818 | NA                                                                                                                                                                    |
| 221 |    254.658880 |    438.696212 | NA                                                                                                                                                                    |
| 222 |    555.590835 |    781.662483 | Scott Hartman                                                                                                                                                         |
| 223 |    683.649409 |    353.341077 | S.Martini                                                                                                                                                             |
| 224 |    490.039469 |    234.061146 | L. Shyamal                                                                                                                                                            |
| 225 |    895.218467 |    391.883435 | Zimices                                                                                                                                                               |
| 226 |    112.832206 |     22.094122 | Zimices                                                                                                                                                               |
| 227 |    988.204985 |    635.503357 | Cathy                                                                                                                                                                 |
| 228 |     73.555477 |    289.774788 | xgirouxb                                                                                                                                                              |
| 229 |    634.606893 |     42.666007 | NA                                                                                                                                                                    |
| 230 |    353.972915 |    590.094663 | Martin R. Smith                                                                                                                                                       |
| 231 |    315.522316 |    782.514667 | T. Michael Keesey                                                                                                                                                     |
| 232 |    752.146682 |    451.389482 | Steven Traver                                                                                                                                                         |
| 233 |    187.792122 |    409.215380 | NA                                                                                                                                                                    |
| 234 |    996.073263 |    520.233217 | Trond R. Oskars                                                                                                                                                       |
| 235 |     42.502611 |    234.030801 | Markus A. Grohme                                                                                                                                                      |
| 236 |    736.767761 |    426.601691 | Jagged Fang Designs                                                                                                                                                   |
| 237 |    988.872876 |    142.983406 | Margot Michaud                                                                                                                                                        |
| 238 |    898.011425 |    112.861866 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 239 |    348.188352 |    336.767069 | T. Michael Keesey                                                                                                                                                     |
| 240 |    240.518019 |    241.266614 | Birgit Lang                                                                                                                                                           |
| 241 |    330.269144 |    708.899613 | Scott Hartman                                                                                                                                                         |
| 242 |    166.242860 |    754.685563 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 243 |     67.266964 |    501.667298 | Matt Crook                                                                                                                                                            |
| 244 |    105.047120 |    183.587852 | Zimices                                                                                                                                                               |
| 245 |     18.939466 |    218.917117 | Mette Aumala                                                                                                                                                          |
| 246 |    453.079789 |    412.436475 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 247 |    284.060258 |     10.035187 | Chris huh                                                                                                                                                             |
| 248 |    238.113256 |    540.242693 | NA                                                                                                                                                                    |
| 249 |    853.120171 |    488.870089 | Ferran Sayol                                                                                                                                                          |
| 250 |     13.090307 |    192.255934 | Zimices                                                                                                                                                               |
| 251 |    842.638796 |    742.064844 | T. Michael Keesey                                                                                                                                                     |
| 252 |    566.745430 |    316.786764 | Mathew Wedel                                                                                                                                                          |
| 253 |    981.833143 |    443.833949 | Margot Michaud                                                                                                                                                        |
| 254 |     30.138735 |    272.194068 | Yan Wong                                                                                                                                                              |
| 255 |    654.755401 |    217.908335 | Christoph Schomburg                                                                                                                                                   |
| 256 |    604.225035 |    128.406601 | George Edward Lodge                                                                                                                                                   |
| 257 |    924.067872 |    390.606215 | Tasman Dixon                                                                                                                                                          |
| 258 |    197.553593 |    276.403381 | Mattia Menchetti                                                                                                                                                      |
| 259 |     49.100808 |    504.127622 | T. Michael Keesey                                                                                                                                                     |
| 260 |    992.055402 |    788.160642 | Stuart Humphries                                                                                                                                                      |
| 261 |     17.438879 |    538.381270 | Matt Crook                                                                                                                                                            |
| 262 |    177.178618 |    216.757627 | NA                                                                                                                                                                    |
| 263 |     83.050642 |    305.833337 | Chris A. Hamilton                                                                                                                                                     |
| 264 |    176.430240 |    168.388752 | T. Michael Keesey                                                                                                                                                     |
| 265 |    717.589725 |    517.954012 | david maas / dave hone                                                                                                                                                |
| 266 |    987.410179 |    251.655070 | Margot Michaud                                                                                                                                                        |
| 267 |    878.756313 |    231.947293 | Matt Crook                                                                                                                                                            |
| 268 |    647.585213 |    528.593821 | Margot Michaud                                                                                                                                                        |
| 269 |    758.907010 |    590.231968 | Matt Crook                                                                                                                                                            |
| 270 |    271.511315 |    656.448768 | Zimices                                                                                                                                                               |
| 271 |    714.477295 |    479.438140 | Matt Crook                                                                                                                                                            |
| 272 |    613.123248 |    111.626345 | Steven Traver                                                                                                                                                         |
| 273 |    416.025397 |      6.338140 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 274 |     96.607535 |     67.748808 | Emily Willoughby                                                                                                                                                      |
| 275 |    654.022481 |     54.119752 | Tracy A. Heath                                                                                                                                                        |
| 276 |    931.077108 |    428.908421 | Yan Wong                                                                                                                                                              |
| 277 |     36.138159 |    779.722744 | Zimices                                                                                                                                                               |
| 278 |    184.197023 |    245.316407 | Becky Barnes                                                                                                                                                          |
| 279 |    667.821257 |    212.426044 | Jagged Fang Designs                                                                                                                                                   |
| 280 |    576.465658 |    366.758639 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 281 |    652.130870 |    345.623861 | Terpsichores                                                                                                                                                          |
| 282 |    163.627140 |    114.872332 | NA                                                                                                                                                                    |
| 283 |    960.323867 |    498.685972 | Margot Michaud                                                                                                                                                        |
| 284 |    225.230414 |    622.878497 | Robert Gay                                                                                                                                                            |
| 285 |    801.695885 |    526.036470 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 286 |    634.893900 |    353.632376 | NA                                                                                                                                                                    |
| 287 |    894.451837 |    213.574480 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 288 |     62.168034 |     23.506788 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 289 |   1016.793593 |    301.109529 | Yan Wong                                                                                                                                                              |
| 290 |    353.983407 |    193.642835 | T. Michael Keesey                                                                                                                                                     |
| 291 |    996.360771 |    277.511472 | Margot Michaud                                                                                                                                                        |
| 292 |    946.359393 |    570.737107 | Markus A. Grohme                                                                                                                                                      |
| 293 |    943.223233 |     45.368538 | Scott Hartman                                                                                                                                                         |
| 294 |    152.636879 |    654.486949 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 295 |    413.094145 |    228.764361 | Katie S. Collins                                                                                                                                                      |
| 296 |    219.357795 |    252.924563 | Roderic Page and Lois Page                                                                                                                                            |
| 297 |    724.855246 |    192.929979 | Maija Karala                                                                                                                                                          |
| 298 |    269.241727 |    382.457781 | Iain Reid                                                                                                                                                             |
| 299 |    921.458984 |    453.768094 | B. Duygu Özpolat                                                                                                                                                      |
| 300 |    177.129199 |    656.447297 | Mathieu Basille                                                                                                                                                       |
| 301 |     55.827638 |    214.618042 | Margot Michaud                                                                                                                                                        |
| 302 |     72.635817 |    372.438189 | Zimices                                                                                                                                                               |
| 303 |    105.947326 |     29.616052 | Margot Michaud                                                                                                                                                        |
| 304 |    620.555525 |    423.468269 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 305 |    235.680399 |    158.209969 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 306 |    476.268228 |    151.055388 | Chloé Schmidt                                                                                                                                                         |
| 307 |    659.059212 |    493.005305 | Jaime Headden                                                                                                                                                         |
| 308 |    818.256342 |    733.843524 | Julia B McHugh                                                                                                                                                        |
| 309 |    401.036588 |    135.508789 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 310 |     31.328169 |    568.533018 | Maija Karala                                                                                                                                                          |
| 311 |    193.235877 |    267.525231 | Maija Karala                                                                                                                                                          |
| 312 |   1003.041893 |      6.993244 | Fernando Campos De Domenico                                                                                                                                           |
| 313 |     34.058683 |    395.639063 | Matt Crook                                                                                                                                                            |
| 314 |    968.598463 |    780.955038 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 315 |    780.393499 |    787.010288 | Matt Crook                                                                                                                                                            |
| 316 |    283.802527 |    744.070011 | Ignacio Contreras                                                                                                                                                     |
| 317 |    425.459275 |    637.609047 | Chase Brownstein                                                                                                                                                      |
| 318 |   1014.229899 |    136.727326 | Tasman Dixon                                                                                                                                                          |
| 319 |     83.657124 |    679.325173 | Margot Michaud                                                                                                                                                        |
| 320 |    526.862043 |    450.389148 | Marie Russell                                                                                                                                                         |
| 321 |    882.361068 |    639.893992 | C. Camilo Julián-Caballero                                                                                                                                            |
| 322 |    798.761878 |    736.990695 | Alexandre Vong                                                                                                                                                        |
| 323 |    990.675257 |     38.041653 | Andy Wilson                                                                                                                                                           |
| 324 |    934.344173 |    394.482917 | L. Shyamal                                                                                                                                                            |
| 325 |    477.721638 |    744.673467 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 326 |    381.730582 |    288.600873 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 327 |    303.697615 |    716.549358 | Matt Martyniuk                                                                                                                                                        |
| 328 |    926.449038 |    119.974908 | Scott Hartman                                                                                                                                                         |
| 329 |    711.536901 |    192.969647 | T. Michael Keesey                                                                                                                                                     |
| 330 |    353.224015 |    609.468485 | Margot Michaud                                                                                                                                                        |
| 331 |    165.499766 |    610.662378 | Jonathan Wells                                                                                                                                                        |
| 332 |     81.556690 |    755.656435 | Milton Tan                                                                                                                                                            |
| 333 |    666.855859 |    547.120155 | Matt Crook                                                                                                                                                            |
| 334 |     87.516393 |    689.836274 | Gareth Monger                                                                                                                                                         |
| 335 |    871.293214 |    516.041903 | Dean Schnabel                                                                                                                                                         |
| 336 |    485.036443 |    759.283761 | T. Michael Keesey                                                                                                                                                     |
| 337 |    721.744848 |    766.058426 | NA                                                                                                                                                                    |
| 338 |    775.786709 |    168.866411 | Noah Schlottman                                                                                                                                                       |
| 339 |    445.687063 |    668.391430 | Christoph Schomburg                                                                                                                                                   |
| 340 |    980.066332 |    778.613320 | Gareth Monger                                                                                                                                                         |
| 341 |    986.169433 |    502.374412 | Matt Crook                                                                                                                                                            |
| 342 |    197.028388 |    289.385686 | Marie-Aimée Allard                                                                                                                                                    |
| 343 |     75.536156 |    387.094882 | Gareth Monger                                                                                                                                                         |
| 344 |    597.061405 |    328.394123 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 345 |    631.345326 |    495.201391 | C. Camilo Julián-Caballero                                                                                                                                            |
| 346 |    712.528559 |    418.181432 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 347 |    214.114418 |    575.895829 | Fernando Carezzano                                                                                                                                                    |
| 348 |    297.201845 |    521.698567 | Ferran Sayol                                                                                                                                                          |
| 349 |    340.141394 |    358.897291 | T. Michael Keesey                                                                                                                                                     |
| 350 |    828.358195 |    211.425417 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 351 |    959.057876 |    576.248902 | Scott Hartman                                                                                                                                                         |
| 352 |    586.511522 |    420.404789 | Noah Schlottman                                                                                                                                                       |
| 353 |    239.337333 |    413.459496 | NA                                                                                                                                                                    |
| 354 |    618.179366 |    440.792903 | Chuanixn Yu                                                                                                                                                           |
| 355 |    458.516873 |    544.764572 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 356 |    631.012800 |    474.005534 | Christoph Schomburg                                                                                                                                                   |
| 357 |    614.016068 |    670.852632 | Scott Hartman                                                                                                                                                         |
| 358 |    822.574619 |    766.367535 | Alexandra van der Geer                                                                                                                                                |
| 359 |     73.258657 |    297.869819 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 360 |    474.252753 |    227.620013 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 361 |    527.095387 |    461.858272 | David Orr                                                                                                                                                             |
| 362 |    631.623567 |    331.731743 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 363 |    879.075663 |     67.879850 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 364 |    290.402284 |    755.985953 | NA                                                                                                                                                                    |
| 365 |    213.170149 |    270.095004 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 366 |   1000.477425 |     30.892925 | NA                                                                                                                                                                    |
| 367 |    875.198809 |    677.797074 | V. Deepak                                                                                                                                                             |
| 368 |    881.139658 |     16.164524 | Zimices                                                                                                                                                               |
| 369 |    410.744136 |    189.315131 | L. Shyamal                                                                                                                                                            |
| 370 |    748.489186 |    632.946480 | Jagged Fang Designs                                                                                                                                                   |
| 371 |    365.219496 |    631.231454 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 372 |    229.203988 |    790.076124 | Beth Reinke                                                                                                                                                           |
| 373 |    636.840014 |    377.405543 | Matt Crook                                                                                                                                                            |
| 374 |    776.983230 |    146.172548 | Steven Traver                                                                                                                                                         |
| 375 |    200.994061 |    351.314491 | Smokeybjb                                                                                                                                                             |
| 376 |    431.061336 |    120.498271 | Margot Michaud                                                                                                                                                        |
| 377 |    622.679864 |    724.062586 | Margot Michaud                                                                                                                                                        |
| 378 |    483.777420 |    168.152300 | Gareth Monger                                                                                                                                                         |
| 379 |    405.508231 |    656.505595 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 380 |    416.722688 |     26.417995 | C. Camilo Julián-Caballero                                                                                                                                            |
| 381 |    907.898294 |    345.216663 | Scott Hartman                                                                                                                                                         |
| 382 |    681.691432 |    570.800361 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 383 |    935.712295 |    784.361575 | Ferran Sayol                                                                                                                                                          |
| 384 |     30.006845 |     24.711135 | Ignacio Contreras                                                                                                                                                     |
| 385 |    807.912894 |    271.694050 | Steven Traver                                                                                                                                                         |
| 386 |    462.614242 |    514.295847 | Matt Martyniuk                                                                                                                                                        |
| 387 |     82.256356 |    357.473541 | Yan Wong                                                                                                                                                              |
| 388 |    157.466373 |    737.118495 | Gareth Monger                                                                                                                                                         |
| 389 |    513.588240 |    242.284844 | Steven Traver                                                                                                                                                         |
| 390 |    770.036083 |    385.519356 | Jagged Fang Designs                                                                                                                                                   |
| 391 |    867.034152 |     77.611291 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 392 |     21.069006 |    475.525455 | Benjamin Monod-Broca                                                                                                                                                  |
| 393 |    163.209879 |    125.928136 | Lukasiniho                                                                                                                                                            |
| 394 |    704.349370 |    289.698101 | Steven Traver                                                                                                                                                         |
| 395 |    465.832319 |    641.618157 | Manabu Bessho-Uehara                                                                                                                                                  |
| 396 |   1000.263104 |    678.744335 | Matt Crook                                                                                                                                                            |
| 397 |    814.875925 |    665.513958 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 398 |    416.316869 |    151.099089 | Margot Michaud                                                                                                                                                        |
| 399 |    156.333651 |    624.290716 | Iain Reid                                                                                                                                                             |
| 400 |    216.666614 |     21.775254 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 401 |     52.596400 |    190.485169 | Zimices                                                                                                                                                               |
| 402 |    281.160932 |    417.882506 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 403 |    505.722110 |     13.408796 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 404 |    953.022002 |    586.665226 | Scott Hartman                                                                                                                                                         |
| 405 |   1012.571556 |     61.445166 | Matt Martyniuk                                                                                                                                                        |
| 406 |     75.944742 |    122.140723 | Andy Wilson                                                                                                                                                           |
| 407 |    575.635753 |    213.685777 | Jaime Headden                                                                                                                                                         |
| 408 |    396.316417 |    259.729269 | Ignacio Contreras                                                                                                                                                     |
| 409 |    430.231684 |    272.948495 | Chase Brownstein                                                                                                                                                      |
| 410 |    777.166017 |    747.569190 | Maxime Dahirel                                                                                                                                                        |
| 411 |    555.584833 |    204.274141 | Steven Traver                                                                                                                                                         |
| 412 |    378.143741 |    252.210093 | Steven Traver                                                                                                                                                         |
| 413 |    177.130424 |    314.312574 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 414 |    416.425739 |    244.243295 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 415 |    746.745156 |    186.912659 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 416 |    313.323513 |    508.402852 | Zimices                                                                                                                                                               |
| 417 |    257.500065 |    668.809352 | Christoph Schomburg                                                                                                                                                   |
| 418 |    407.828127 |    449.464708 | Dean Schnabel                                                                                                                                                         |
| 419 |    971.259241 |    616.285841 | Gareth Monger                                                                                                                                                         |
| 420 |    875.559714 |    610.118468 | T. Michael Keesey                                                                                                                                                     |
| 421 |     18.525561 |    596.014629 | Margot Michaud                                                                                                                                                        |
| 422 |    225.052007 |    291.689725 | Margot Michaud                                                                                                                                                        |
| 423 |    909.339941 |    764.672697 | Zimices                                                                                                                                                               |
| 424 |     84.488139 |    720.132077 | Gareth Monger                                                                                                                                                         |
| 425 |    308.438548 |    652.409765 | NA                                                                                                                                                                    |
| 426 |    586.928344 |    396.272417 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 427 |    594.172866 |    455.786006 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 428 |     38.554086 |     44.523443 | Kai R. Caspar                                                                                                                                                         |
| 429 |    393.761802 |    702.560833 | Jimmy Bernot                                                                                                                                                          |
| 430 |    101.078838 |     90.616086 | Gareth Monger                                                                                                                                                         |
| 431 |    114.841341 |    670.365621 | CNZdenek                                                                                                                                                              |
| 432 |    296.530024 |    337.968574 | Ferran Sayol                                                                                                                                                          |
| 433 |    844.479029 |    353.379325 | Sarah Werning                                                                                                                                                         |
| 434 |     89.548139 |    710.088841 | Zimices                                                                                                                                                               |
| 435 |     80.063436 |     54.419443 | Matt Hayes                                                                                                                                                            |
| 436 |    276.263179 |    431.887048 | M. A. Broussard                                                                                                                                                       |
| 437 |     23.753767 |    242.467441 | Andy Wilson                                                                                                                                                           |
| 438 |    606.235388 |    608.809543 | Margot Michaud                                                                                                                                                        |
| 439 |    514.622883 |    437.801697 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 440 |    899.157678 |    451.763367 | Tracy A. Heath                                                                                                                                                        |
| 441 |    616.148513 |     65.995238 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 442 |   1014.906533 |    752.859421 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 443 |    743.245315 |    644.407733 | Ferran Sayol                                                                                                                                                          |
| 444 |    763.582400 |    184.598906 | Birgit Lang                                                                                                                                                           |
| 445 |    602.567990 |    104.404057 | Tracy A. Heath                                                                                                                                                        |
| 446 |    974.438081 |    668.756696 | Matt Crook                                                                                                                                                            |
| 447 |    879.254237 |     37.907543 | Zimices                                                                                                                                                               |
| 448 |    444.213459 |    764.945765 | Chris huh                                                                                                                                                             |
| 449 |    731.317096 |    778.912581 | Scott Hartman                                                                                                                                                         |
| 450 |    905.015356 |    795.946256 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 451 |    784.661681 |    191.544039 | Scott Hartman                                                                                                                                                         |
| 452 |    788.929161 |    479.853896 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 453 |    203.369078 |    665.693134 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 454 |    146.838783 |      5.713856 | Matt Crook                                                                                                                                                            |
| 455 |    435.981395 |    680.076858 | T. Michael Keesey                                                                                                                                                     |
| 456 |     51.761947 |    385.429782 | Alex Slavenko                                                                                                                                                         |
| 457 |    419.390811 |    659.633174 | Jiekun He                                                                                                                                                             |
| 458 |     76.998162 |    147.815954 | Crystal Maier                                                                                                                                                         |
| 459 |    330.548034 |    185.899663 | Joanna Wolfe                                                                                                                                                          |
| 460 |    384.339703 |    772.350339 | FunkMonk                                                                                                                                                              |
| 461 |    355.450933 |    530.508002 | Ferran Sayol                                                                                                                                                          |
| 462 |    806.110642 |    511.023063 | Zimices                                                                                                                                                               |
| 463 |    263.863167 |    449.407064 | Margot Michaud                                                                                                                                                        |
| 464 |    428.460198 |    152.288861 | NA                                                                                                                                                                    |
| 465 |    290.083983 |    174.220530 | Jaime Headden                                                                                                                                                         |
| 466 |    632.967510 |    608.148741 | Steven Coombs                                                                                                                                                         |
| 467 |    973.243688 |    686.827642 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 468 |    786.612268 |    495.623137 | Matt Crook                                                                                                                                                            |
| 469 |    136.671316 |    403.240764 | Ferran Sayol                                                                                                                                                          |
| 470 |    480.852317 |     70.147982 | Christian A. Masnaghetti                                                                                                                                              |
| 471 |    879.176297 |    380.275061 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 472 |    329.928750 |    365.928612 | Louis Ranjard                                                                                                                                                         |
| 473 |    282.796904 |    404.679569 | Chris huh                                                                                                                                                             |
| 474 |    437.308533 |    534.585904 | Chris huh                                                                                                                                                             |
| 475 |    256.070866 |    298.654720 | Scott Hartman                                                                                                                                                         |
| 476 |    222.757084 |    550.675174 | Jagged Fang Designs                                                                                                                                                   |
| 477 |    279.675773 |    521.666223 | Tasman Dixon                                                                                                                                                          |
| 478 |    538.470243 |    301.403760 | Markus A. Grohme                                                                                                                                                      |
| 479 |    971.756840 |    150.957707 | Matt Crook                                                                                                                                                            |
| 480 |    970.216656 |    602.158341 | Margot Michaud                                                                                                                                                        |
| 481 |    779.353723 |    559.612395 | Gareth Monger                                                                                                                                                         |
| 482 |    188.628409 |    184.171007 | Amanda Katzer                                                                                                                                                         |
| 483 |    501.646278 |    725.550016 | T. Michael Keesey                                                                                                                                                     |
| 484 |    639.513878 |     75.487789 | Dean Schnabel                                                                                                                                                         |
| 485 |    316.521652 |    170.375308 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 486 |    733.621269 |      8.518379 | Lily Hughes                                                                                                                                                           |
| 487 |    784.508319 |    353.333384 | Gareth Monger                                                                                                                                                         |
| 488 |    109.534721 |    108.977219 | Cesar Julian                                                                                                                                                          |
| 489 |    457.584958 |    149.587248 | Tracy A. Heath                                                                                                                                                        |
| 490 |    203.097390 |    676.053392 | NA                                                                                                                                                                    |
| 491 |    601.911511 |    641.151887 | Ferran Sayol                                                                                                                                                          |
| 492 |    959.037014 |     23.409866 | Gareth Monger                                                                                                                                                         |
| 493 |    173.794529 |    402.594021 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 494 |    123.493518 |    262.172016 | Ferran Sayol                                                                                                                                                          |
| 495 |    847.453688 |    155.412670 | Andrew A. Farke                                                                                                                                                       |
| 496 |    458.767678 |    739.601175 | Matt Crook                                                                                                                                                            |
| 497 |    807.860050 |    788.818808 | Collin Gross                                                                                                                                                          |
| 498 |    791.569269 |     39.036559 | Zimices                                                                                                                                                               |
| 499 |    343.742803 |    198.518874 | Alexandre Vong                                                                                                                                                        |
| 500 |   1003.447528 |     50.228572 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 501 |    512.532327 |    775.256461 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 502 |    855.477913 |    377.653272 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 503 |    980.793670 |     25.766333 | Margot Michaud                                                                                                                                                        |
| 504 |    115.192030 |    195.106133 | Shyamal                                                                                                                                                               |
| 505 |    792.842722 |    169.267859 | Zimices                                                                                                                                                               |
| 506 |   1014.111167 |    271.343337 | Katie S. Collins                                                                                                                                                      |
| 507 |    827.904189 |    742.509741 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 508 |    304.771832 |    297.467652 | NA                                                                                                                                                                    |
| 509 |    691.615429 |    539.214105 | Andy Wilson                                                                                                                                                           |
| 510 |    115.265985 |    304.078482 | Kamil S. Jaron                                                                                                                                                        |
| 511 |    835.688010 |    290.902644 | Margot Michaud                                                                                                                                                        |
| 512 |     91.139900 |    293.309970 | Matt Crook                                                                                                                                                            |
| 513 |     82.153866 |    269.488341 | NA                                                                                                                                                                    |
| 514 |    833.678098 |    670.205316 | Collin Gross                                                                                                                                                          |
| 515 |    814.860654 |    263.071531 | Sarah Werning                                                                                                                                                         |
| 516 |     84.362222 |    513.748714 | Zimices                                                                                                                                                               |
| 517 |    129.560008 |    351.431706 | Ignacio Contreras                                                                                                                                                     |
| 518 |    954.863586 |    420.563984 | T. Michael Keesey                                                                                                                                                     |
| 519 |    823.187767 |    558.367530 | Ferran Sayol                                                                                                                                                          |
| 520 |    773.059567 |     65.548137 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 521 |    670.112905 |    196.457542 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 522 |    326.264591 |    767.575799 | Elizabeth Parker                                                                                                                                                      |
| 523 |    648.049857 |    583.748850 | Alex Slavenko                                                                                                                                                         |
| 524 |    110.015225 |    702.195307 | Matt Crook                                                                                                                                                            |
| 525 |    315.747006 |    137.199982 | Steven Traver                                                                                                                                                         |
| 526 |    212.720485 |    154.373708 | Jaime Headden                                                                                                                                                         |
| 527 |    248.815365 |    136.807135 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 528 |    687.483677 |    198.740712 | Zimices                                                                                                                                                               |
| 529 |    575.769255 |    345.290782 | John Conway                                                                                                                                                           |
| 530 |    988.831308 |    619.062830 | Jack Mayer Wood                                                                                                                                                       |
| 531 |    211.481249 |    681.142345 | Chris huh                                                                                                                                                             |
| 532 |    549.750291 |    238.495018 | Zimices                                                                                                                                                               |
| 533 |    155.375887 |    309.331497 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 534 |    574.351193 |    324.520820 | Mathieu Pélissié                                                                                                                                                      |
| 535 |    193.081120 |    326.545839 | Chase Brownstein                                                                                                                                                      |
| 536 |    937.308965 |    362.578771 | Gareth Monger                                                                                                                                                         |
| 537 |    513.486168 |    591.139752 | Ferran Sayol                                                                                                                                                          |
| 538 |    171.303948 |    183.756855 | Maxime Dahirel                                                                                                                                                        |
| 539 |    800.502958 |    389.571047 | Crystal Maier                                                                                                                                                         |
| 540 |    317.683499 |    365.461487 | FJDegrange                                                                                                                                                            |
| 541 |    671.404951 |    456.152513 | Collin Gross                                                                                                                                                          |
| 542 |    889.363612 |    473.745882 | Dean Schnabel                                                                                                                                                         |
| 543 |     34.370248 |    205.673496 | Steven Traver                                                                                                                                                         |
| 544 |   1019.532596 |    391.439711 | Gareth Monger                                                                                                                                                         |
| 545 |    783.839414 |    379.376852 | NA                                                                                                                                                                    |
| 546 |    109.463172 |    445.427961 | Chuanixn Yu                                                                                                                                                           |
| 547 |    257.948969 |    358.047673 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
| 548 |    840.050513 |    150.094220 | Milton Tan                                                                                                                                                            |
| 549 |    442.800695 |    367.155326 | Kent Elson Sorgon                                                                                                                                                     |
| 550 |    973.397792 |    490.220930 | Margot Michaud                                                                                                                                                        |
| 551 |    882.241360 |    709.154154 | Jagged Fang Designs                                                                                                                                                   |
| 552 |    488.150631 |    623.315867 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 553 |    995.904502 |    292.631893 | Zimices                                                                                                                                                               |
| 554 |    694.186008 |    487.874953 | Claus Rebler                                                                                                                                                          |
| 555 |    597.473209 |    786.716437 | Margot Michaud                                                                                                                                                        |
| 556 |    838.956838 |    206.871465 | Scott Hartman                                                                                                                                                         |
| 557 |    577.875548 |    792.477732 | Ferran Sayol                                                                                                                                                          |
| 558 |    305.876106 |    369.462805 | Margot Michaud                                                                                                                                                        |
| 559 |    231.664839 |    147.531682 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 560 |    202.096313 |    180.831606 | Andy Wilson                                                                                                                                                           |
| 561 |    499.162238 |    448.930200 | Lani Mohan                                                                                                                                                            |
| 562 |    391.528560 |    676.325643 | Markus A. Grohme                                                                                                                                                      |
| 563 |    903.637746 |    709.564797 | T. Tischler                                                                                                                                                           |
| 564 |    738.896902 |    573.025623 | Chuanixn Yu                                                                                                                                                           |
| 565 |    367.081640 |    321.393625 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 566 |    642.064986 |     33.510595 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 567 |    987.165995 |    595.458221 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
| 568 |    308.860053 |    705.387079 | Xavier Giroux-Bougard                                                                                                                                                 |
| 569 |     47.228462 |    415.392678 | Margot Michaud                                                                                                                                                        |
| 570 |    899.439283 |    233.817413 | Beth Reinke                                                                                                                                                           |
| 571 |    323.519149 |    199.501128 | Sharon Wegner-Larsen                                                                                                                                                  |
| 572 |    824.240380 |    488.927543 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 573 |    155.807168 |    475.698414 | Margot Michaud                                                                                                                                                        |
| 574 |    134.873559 |    273.467359 | Jaime Headden                                                                                                                                                         |
| 575 |    482.492099 |    729.034682 | Ferran Sayol                                                                                                                                                          |
| 576 |     33.606474 |    595.713951 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 577 |     66.809589 |    564.527441 | NA                                                                                                                                                                    |
| 578 |    811.859784 |    206.998940 | Sarah Werning                                                                                                                                                         |
| 579 |   1008.282094 |    586.167521 | Margot Michaud                                                                                                                                                        |
| 580 |    929.333431 |    441.109475 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 581 |     26.726830 |    650.225333 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 582 |     17.418572 |    656.921544 | Jagged Fang Designs                                                                                                                                                   |
| 583 |    685.143504 |    727.714040 | Rebecca Groom                                                                                                                                                         |
| 584 |     93.413562 |    424.092175 | Steven Traver                                                                                                                                                         |
| 585 |    930.408279 |    637.211434 | Jagged Fang Designs                                                                                                                                                   |
| 586 |    593.846190 |    322.591121 | Scott Hartman                                                                                                                                                         |
| 587 |    425.245379 |    541.943510 | Dean Schnabel                                                                                                                                                         |
| 588 |    888.641291 |     57.716848 | Mathew Wedel                                                                                                                                                          |
| 589 |    525.931861 |     28.952834 | L. Shyamal                                                                                                                                                            |
| 590 |    314.037676 |    351.272323 | Chris huh                                                                                                                                                             |
| 591 |    267.162951 |    681.105165 | Andy Wilson                                                                                                                                                           |
| 592 |    915.607487 |    212.687947 | Joanna Wolfe                                                                                                                                                          |
| 593 |    852.613347 |    440.196965 | Andy Wilson                                                                                                                                                           |
| 594 |    866.102536 |     86.469731 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 595 |    989.327834 |    345.493874 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 596 |    372.229875 |    423.297671 | Scott Hartman                                                                                                                                                         |
| 597 |    244.205656 |    447.105730 | Chris huh                                                                                                                                                             |
| 598 |    853.929932 |    355.861977 | Xavier Giroux-Bougard                                                                                                                                                 |
| 599 |    362.413948 |    198.765027 | Melissa Broussard                                                                                                                                                     |
| 600 |    431.269305 |    500.027759 | Matt Wilkins                                                                                                                                                          |
| 601 |     63.123411 |    262.616257 | Steven Traver                                                                                                                                                         |
| 602 |    317.498322 |    495.882891 | Tauana J. Cunha                                                                                                                                                       |
| 603 |     20.430130 |    254.054052 | Becky Barnes                                                                                                                                                          |
| 604 |    891.107529 |    489.792074 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 605 |    738.291177 |    176.456976 | FunkMonk (Michael B. H.)                                                                                                                                              |
| 606 |    963.916092 |    763.806609 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 607 |    178.192176 |    196.475231 | Zimices                                                                                                                                                               |
| 608 |    456.440971 |    563.391538 | Felix Vaux                                                                                                                                                            |
| 609 |    454.446301 |    181.661306 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 610 |     27.766097 |    351.721620 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 611 |    116.611511 |    615.403385 | Roberto Díaz Sibaja                                                                                                                                                   |
| 612 |    199.701444 |    493.671675 | Sarah Werning                                                                                                                                                         |
| 613 |    948.007015 |    771.969576 | T. Michael Keesey                                                                                                                                                     |
| 614 |    957.978567 |    346.889878 | Margot Michaud                                                                                                                                                        |
| 615 |    422.629933 |    199.949724 | Chris huh                                                                                                                                                             |
| 616 |    330.256933 |    749.879700 | Margot Michaud                                                                                                                                                        |
| 617 |    403.262768 |    461.088754 | Andy Wilson                                                                                                                                                           |
| 618 |    511.519198 |     19.607668 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 619 |    362.949604 |    582.536538 | Matt Crook                                                                                                                                                            |
| 620 |    988.594310 |    495.499630 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 621 |    661.091763 |    330.662224 | Scott Hartman                                                                                                                                                         |
| 622 |    217.075952 |    179.139352 | Zimices                                                                                                                                                               |
| 623 |    721.854223 |    284.368001 | NA                                                                                                                                                                    |
| 624 |    878.372640 |    356.406709 | NA                                                                                                                                                                    |
| 625 |     37.338176 |    670.253983 | Zimices                                                                                                                                                               |
| 626 |    638.516333 |     56.145354 | Michelle Site                                                                                                                                                         |
| 627 |    787.747430 |    582.706370 | Matt Crook                                                                                                                                                            |
| 628 |    428.662041 |     94.153714 | Ferran Sayol                                                                                                                                                          |
| 629 |    337.270454 |    209.114111 | Christoph Schomburg                                                                                                                                                   |
| 630 |    335.265044 |    253.732877 | David Orr                                                                                                                                                             |
| 631 |    540.054285 |     98.121647 | Ferran Sayol                                                                                                                                                          |
| 632 |    179.001340 |    498.289420 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 633 |    346.283920 |    139.050229 | Gareth Monger                                                                                                                                                         |
| 634 |    306.087040 |    281.260164 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 635 |    423.994205 |    704.566641 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 636 |    824.193124 |    410.805812 | Christoph Schomburg                                                                                                                                                   |
| 637 |    556.203557 |    582.333985 | Dean Schnabel                                                                                                                                                         |
| 638 |    154.450233 |    611.092097 | T. Michael Keesey (after Mivart)                                                                                                                                      |
| 639 |    471.405407 |     87.951550 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 640 |    576.094204 |    432.329153 | Margot Michaud                                                                                                                                                        |
| 641 |     41.978316 |     50.963053 | NA                                                                                                                                                                    |
| 642 |    546.798424 |    463.220255 | Jagged Fang Designs                                                                                                                                                   |
| 643 |      3.423548 |    751.521552 | Gareth Monger                                                                                                                                                         |
| 644 |    113.882621 |    609.499215 | Margot Michaud                                                                                                                                                        |
| 645 |    427.895051 |    486.098321 | NA                                                                                                                                                                    |
| 646 |    209.588719 |    611.143429 | Anthony Caravaggi                                                                                                                                                     |
| 647 |    469.257493 |    609.638776 | Sarah Werning                                                                                                                                                         |
| 648 |    357.943780 |    339.653240 | Steven Traver                                                                                                                                                         |
| 649 |    728.100270 |    243.504433 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 650 |    124.739147 |    679.854710 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 651 |    349.908287 |    262.257015 | Andy Wilson                                                                                                                                                           |
| 652 |    508.196913 |     94.494436 | Steven Traver                                                                                                                                                         |
| 653 |    857.430922 |    747.385456 | Sarah Werning                                                                                                                                                         |
| 654 |    756.385812 |     81.478279 | Matt Crook                                                                                                                                                            |
| 655 |    415.273573 |    623.722374 | New York Zoological Society                                                                                                                                           |
| 656 |    226.722740 |    266.193214 | Steven Traver                                                                                                                                                         |
| 657 |    191.027128 |     93.191095 | Scott Hartman                                                                                                                                                         |
| 658 |    258.509842 |    787.830942 | Margot Michaud                                                                                                                                                        |
| 659 |    162.099296 |    504.450732 | Matt Martyniuk                                                                                                                                                        |
| 660 |    214.132621 |    560.325906 | Gareth Monger                                                                                                                                                         |
| 661 |    153.150904 |    272.571555 | Josefine Bohr Brask                                                                                                                                                   |
| 662 |    620.027723 |    707.412342 | Matt Crook                                                                                                                                                            |
| 663 |    998.725302 |    314.934912 | NA                                                                                                                                                                    |
| 664 |    110.789520 |    691.741282 | Inessa Voet                                                                                                                                                           |
| 665 |     25.215808 |    362.631572 | Jagged Fang Designs                                                                                                                                                   |
| 666 |    783.340341 |    594.410265 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 667 |    852.120474 |    294.424073 | Steven Traver                                                                                                                                                         |
| 668 |    216.060214 |    526.308131 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 669 |    637.764456 |    699.775679 | Ferran Sayol                                                                                                                                                          |
| 670 |    639.982446 |     86.230700 | Ferran Sayol                                                                                                                                                          |
| 671 |    334.341141 |    309.697599 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 672 |    428.639868 |    648.317037 | Jiekun He                                                                                                                                                             |
| 673 |    248.995729 |    683.775105 | Zimices                                                                                                                                                               |
| 674 |    655.239697 |    485.608082 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 675 |    933.793982 |    794.369420 | Ghedoghedo                                                                                                                                                            |
| 676 |    607.349433 |    351.689264 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 677 |    116.298406 |    460.019742 | Andrew A. Farke                                                                                                                                                       |
| 678 |    639.747023 |    239.814945 | Jaime Headden                                                                                                                                                         |
| 679 |     41.530435 |     32.848583 | Margot Michaud                                                                                                                                                        |
| 680 |    671.375996 |    281.080681 | Steven Traver                                                                                                                                                         |
| 681 |    215.439449 |    664.105616 | Jagged Fang Designs                                                                                                                                                   |
| 682 |    681.727262 |    541.900491 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 683 |    224.807641 |    506.820181 | Margot Michaud                                                                                                                                                        |
| 684 |    117.754956 |    403.337610 | Chase Brownstein                                                                                                                                                      |
| 685 |    145.716611 |    358.192633 | Margot Michaud                                                                                                                                                        |
| 686 |    802.164708 |    196.264676 | M Hutchinson                                                                                                                                                          |
| 687 |    628.931090 |    228.986069 | Armin Reindl                                                                                                                                                          |
| 688 |    380.639069 |    171.374299 | Matt Crook                                                                                                                                                            |
| 689 |    339.038458 |    164.449090 | Mathilde Cordellier                                                                                                                                                   |
| 690 |   1006.633472 |    688.485865 | Lukasiniho                                                                                                                                                            |
| 691 |    608.254818 |    682.215720 | T. Michael Keesey                                                                                                                                                     |
| 692 |    357.685624 |    746.061369 | Gareth Monger                                                                                                                                                         |
| 693 |    862.159413 |     65.387749 | David Orr                                                                                                                                                             |
| 694 |   1006.014424 |     80.815271 | Carlos Cano-Barbacil                                                                                                                                                  |
| 695 |    739.061957 |    408.581801 | Michelle Site                                                                                                                                                         |
| 696 |   1009.151711 |    149.459146 | Danielle Alba                                                                                                                                                         |
| 697 |    100.784004 |    523.582081 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 698 |    834.261975 |    163.044903 | Ignacio Contreras                                                                                                                                                     |
| 699 |    655.104376 |    192.276213 | Gareth Monger                                                                                                                                                         |
| 700 |    607.072878 |    371.867586 | Noah Schlottman                                                                                                                                                       |
| 701 |    959.784561 |    363.163783 | Sarah Werning                                                                                                                                                         |
| 702 |    180.182074 |    519.075166 | Mathieu Basille                                                                                                                                                       |
| 703 |    625.325721 |    623.929081 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 704 |    690.872108 |    182.172332 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 705 |    940.741961 |    622.635367 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 706 |    224.314636 |    444.043267 | Davidson Sodré                                                                                                                                                        |
| 707 |    711.784183 |    570.380834 | Matt Crook                                                                                                                                                            |
| 708 |    682.958394 |    328.656125 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 709 |    836.108682 |    563.732374 | NA                                                                                                                                                                    |
| 710 |     22.166417 |     39.641353 | DW Bapst (modified from Mitchell 1990)                                                                                                                                |
| 711 |    122.948666 |    516.454268 | Erika Schumacher                                                                                                                                                      |
| 712 |    263.208711 |    179.951345 | Andy Wilson                                                                                                                                                           |
| 713 |    710.800542 |    589.582010 | Gareth Monger                                                                                                                                                         |
| 714 |    668.189143 |    397.702609 | Scott Hartman                                                                                                                                                         |
| 715 |    872.737607 |    250.891073 | L. Shyamal                                                                                                                                                            |
| 716 |   1006.379133 |    512.893304 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 717 |    816.295907 |    521.335935 | Margot Michaud                                                                                                                                                        |
| 718 |    745.655595 |    791.992954 | Jagged Fang Designs                                                                                                                                                   |
| 719 |    360.914387 |    546.120178 | Dean Schnabel                                                                                                                                                         |
| 720 |    909.754112 |    574.755995 | NA                                                                                                                                                                    |
| 721 |    972.180001 |    241.749169 | Chris huh                                                                                                                                                             |
| 722 |    435.680494 |    659.334001 | Matt Crook                                                                                                                                                            |
| 723 |    578.535673 |    579.451310 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 724 |    352.196758 |    624.286084 | Markus A. Grohme                                                                                                                                                      |
| 725 |    159.835021 |    702.873960 | Gareth Monger                                                                                                                                                         |
| 726 |   1017.242777 |    185.032678 | Xavier Giroux-Bougard                                                                                                                                                 |
| 727 |    394.586990 |    241.560531 | Zimices                                                                                                                                                               |
| 728 |    727.051553 |    530.725557 | Jagged Fang Designs                                                                                                                                                   |
| 729 |    260.379691 |    526.545653 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                          |
| 730 |    187.184445 |    590.413968 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 731 |    557.290124 |    209.607736 | Chris huh                                                                                                                                                             |
| 732 |     11.651055 |    677.756957 | Matt Crook                                                                                                                                                            |
| 733 |    669.918845 |    143.642506 | Milton Tan                                                                                                                                                            |
| 734 |    308.548101 |    250.920384 | Scott Hartman                                                                                                                                                         |
| 735 |    103.592716 |    204.769310 | Chris huh                                                                                                                                                             |
| 736 |    218.416094 |    304.430216 | Steven Traver                                                                                                                                                         |
| 737 |    140.390136 |    664.230643 | Zimices                                                                                                                                                               |
| 738 |    153.384557 |    729.391628 | Matt Crook                                                                                                                                                            |
| 739 |    354.260067 |    661.617779 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 740 |   1005.103110 |    134.453828 | Gareth Monger                                                                                                                                                         |
| 741 |    807.380671 |    596.311787 | \[unknown\]                                                                                                                                                           |
| 742 |    478.284411 |    445.662048 | Margot Michaud                                                                                                                                                        |
| 743 |     97.113696 |    392.889040 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 744 |    914.762070 |    470.846526 | Harold N Eyster                                                                                                                                                       |
| 745 |    590.155909 |     48.943107 | NA                                                                                                                                                                    |
| 746 |    632.414735 |    467.235335 | Chris huh                                                                                                                                                             |
| 747 |    985.612601 |    263.299733 | Matt Crook                                                                                                                                                            |
| 748 |    410.791940 |    408.656523 | Florian Pfaff                                                                                                                                                         |
| 749 |     16.428947 |    288.846996 | Tony Ayling                                                                                                                                                           |
| 750 |    978.070491 |    765.294927 | Mattia Menchetti                                                                                                                                                      |
| 751 |    490.959598 |     14.797455 | Scott Hartman                                                                                                                                                         |
| 752 |   1014.972420 |    230.424811 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 753 |    407.523489 |    160.403768 | NA                                                                                                                                                                    |
| 754 |    453.643600 |    771.921076 | Dean Schnabel                                                                                                                                                         |
| 755 |    745.892322 |    610.340714 | NA                                                                                                                                                                    |
| 756 |    177.878091 |    153.700267 | Felix Vaux                                                                                                                                                            |
| 757 |    605.199976 |    660.516409 | Scott Hartman                                                                                                                                                         |
| 758 |    156.693090 |    490.822444 | Ferran Sayol                                                                                                                                                          |
| 759 |    873.096837 |    389.947943 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 760 |    791.495964 |     57.817687 | Matt Crook                                                                                                                                                            |
| 761 |    434.246866 |    135.405195 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 762 |    567.619928 |    602.345533 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 763 |    915.982481 |    727.882516 | Gareth Monger                                                                                                                                                         |
| 764 |   1007.087863 |    654.577566 | Matt Crook                                                                                                                                                            |
| 765 |    398.638084 |    440.019262 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 766 |      9.934807 |    460.522161 | Jack Mayer Wood                                                                                                                                                       |
| 767 |    833.191866 |    103.663736 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 768 |   1009.675261 |    787.065945 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 769 |    689.359783 |    210.150954 | Matt Crook                                                                                                                                                            |
| 770 |    115.300184 |    478.395081 | Margot Michaud                                                                                                                                                        |
| 771 |     27.362160 |    791.534173 | Chris huh                                                                                                                                                             |
| 772 |    240.011144 |    117.830376 | Nina Skinner                                                                                                                                                          |
| 773 |     77.359386 |    113.100179 | Gareth Monger                                                                                                                                                         |
| 774 |    557.913287 |    573.470070 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 775 |    895.520439 |    687.341531 | Jagged Fang Designs                                                                                                                                                   |
| 776 |    481.809286 |    784.589289 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 777 |    621.395101 |    787.342515 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 778 |    331.439135 |    147.047329 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
| 779 |    325.911761 |    218.477755 | Birgit Lang                                                                                                                                                           |
| 780 |    234.777066 |    549.126166 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 781 |    720.177939 |    638.002347 | Felix Vaux                                                                                                                                                            |
| 782 |    686.876458 |    317.029123 | NA                                                                                                                                                                    |
| 783 |    256.517056 |      8.407438 | Thibaut Brunet                                                                                                                                                        |
| 784 |    424.362863 |    518.169716 | Ingo Braasch                                                                                                                                                          |
| 785 |    883.080434 |    687.670145 | Mathilde Cordellier                                                                                                                                                   |
| 786 |    981.392970 |    454.534889 | Matt Wilkins                                                                                                                                                          |
| 787 |    714.586269 |     18.889144 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 788 |    961.123600 |    623.002150 | Terpsichores                                                                                                                                                          |
| 789 |    797.691826 |    216.202154 | Sarah Werning                                                                                                                                                         |
| 790 |    702.860218 |    430.414584 | Emily Willoughby                                                                                                                                                      |
| 791 |    153.862173 |    401.207463 | Matt Crook                                                                                                                                                            |
| 792 |    264.577046 |    704.673635 | NA                                                                                                                                                                    |
| 793 |    389.004417 |    795.050736 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 794 |    794.898142 |    452.737720 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 795 |    823.127684 |    534.712713 | Alexandre Vong                                                                                                                                                        |
| 796 |    525.856595 |     40.639527 | Renato de Carvalho Ferreira                                                                                                                                           |
| 797 |    695.008901 |    273.115085 | Jagged Fang Designs                                                                                                                                                   |
| 798 |    833.600938 |    731.558411 | Christoph Schomburg                                                                                                                                                   |
| 799 |     51.747602 |    431.027327 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 800 |    972.990415 |    792.368682 | NA                                                                                                                                                                    |
| 801 |    840.382472 |     76.075095 | Margot Michaud                                                                                                                                                        |
| 802 |    804.494928 |    681.013258 | Scott Hartman                                                                                                                                                         |
| 803 |    246.888853 |    466.972606 | Roberto Díaz Sibaja                                                                                                                                                   |
| 804 |    242.612482 |    791.977939 | Isaure Scavezzoni                                                                                                                                                     |
| 805 |    933.227476 |     90.089016 | Jagged Fang Designs                                                                                                                                                   |
| 806 |    597.171779 |     87.940589 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 807 |    920.841048 |    351.541064 | NA                                                                                                                                                                    |
| 808 |    304.825993 |    759.542798 | Gareth Monger                                                                                                                                                         |
| 809 |    146.878704 |     96.513427 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 810 |    786.782657 |    222.928583 | Ferran Sayol                                                                                                                                                          |
| 811 |    579.770454 |    610.829708 | Collin Gross                                                                                                                                                          |
| 812 |    498.347460 |    744.370287 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 813 |    802.357691 |    689.650188 | Tasman Dixon                                                                                                                                                          |
| 814 |    234.508936 |    517.637684 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 815 |    727.047504 |    271.691458 | NA                                                                                                                                                                    |
| 816 |    827.023963 |    689.848941 | T. Michael Keesey                                                                                                                                                     |
| 817 |    774.893397 |    598.024950 | Ferran Sayol                                                                                                                                                          |
| 818 |    653.467969 |    565.315482 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 819 |    707.287273 |    528.894579 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 820 |    204.818712 |    255.722103 | Scott Hartman                                                                                                                                                         |
| 821 |    350.191675 |    254.334794 | Jake Warner                                                                                                                                                           |
| 822 |    728.769461 |    770.587438 | Jagged Fang Designs                                                                                                                                                   |
| 823 |    297.131208 |    263.971237 | Iain Reid                                                                                                                                                             |
| 824 |    912.110617 |     63.984879 | Mathew Wedel                                                                                                                                                          |
| 825 |     31.118793 |    740.175483 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 826 |      7.853835 |     26.952845 | Jimmy Bernot                                                                                                                                                          |
| 827 |    157.232643 |    666.393406 | Matt Crook                                                                                                                                                            |
| 828 |    997.940251 |    755.835552 | Ferran Sayol                                                                                                                                                          |
| 829 |    998.296358 |    730.280265 | Zimices                                                                                                                                                               |
| 830 |    104.616208 |    102.083225 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 831 |    443.558554 |    503.301532 | NA                                                                                                                                                                    |
| 832 |      4.780583 |    369.699138 | Gareth Monger                                                                                                                                                         |
| 833 |    314.866490 |    186.209796 | Ramona J Heim                                                                                                                                                         |
| 834 |    833.453423 |    436.033948 | Kent Elson Sorgon                                                                                                                                                     |
| 835 |    761.906393 |     59.617574 | Scott Hartman                                                                                                                                                         |
| 836 |     12.887635 |    317.032611 | T. Michael Keesey                                                                                                                                                     |
| 837 |   1014.223303 |    496.199108 | Zimices                                                                                                                                                               |
| 838 |    201.366094 |    236.745537 | L. Shyamal                                                                                                                                                            |
| 839 |    250.814199 |     71.196003 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 840 |    453.817226 |     51.383218 | Matt Crook                                                                                                                                                            |
| 841 |    595.198921 |    215.711806 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                             |
| 842 |    899.838365 |    615.136939 | T. Michael Keesey                                                                                                                                                     |
| 843 |     81.697490 |    196.936259 | Ferran Sayol                                                                                                                                                          |
| 844 |    242.931935 |    255.354237 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 845 |    135.725744 |    299.080081 | wsnaccad                                                                                                                                                              |
| 846 |    438.158074 |    199.895011 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 847 |    182.711623 |    700.078072 | Rebecca Groom                                                                                                                                                         |
| 848 |     42.803895 |    556.597007 | Katie S. Collins                                                                                                                                                      |
| 849 |    547.434557 |    131.276303 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 850 |     10.166270 |    649.010549 | Chris Hay                                                                                                                                                             |
| 851 |     89.043601 |     77.070577 | Kamil S. Jaron                                                                                                                                                        |
| 852 |    672.264388 |    186.507233 | Dmitry Bogdanov                                                                                                                                                       |
| 853 |    408.938139 |    764.645802 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 854 |    852.613898 |    738.263285 | Markus A. Grohme                                                                                                                                                      |
| 855 |    344.304788 |    763.227590 | Matt Crook                                                                                                                                                            |
| 856 |    797.779162 |    567.798747 | Margot Michaud                                                                                                                                                        |
| 857 |    471.960780 |    786.485993 | Alexandre Vong                                                                                                                                                        |
| 858 |     84.929675 |    667.894670 | Tasman Dixon                                                                                                                                                          |
| 859 |    413.349522 |    133.433396 | Beth Reinke                                                                                                                                                           |
| 860 |    556.990909 |    322.885276 | Jagged Fang Designs                                                                                                                                                   |
| 861 |     81.222964 |     39.001041 | Michael Scroggie                                                                                                                                                      |
| 862 |    441.919442 |    179.620853 | Maxime Dahirel                                                                                                                                                        |
| 863 |     11.495504 |    280.143648 | Darius Nau                                                                                                                                                            |
| 864 |    826.730148 |    192.016003 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 865 |    541.792618 |    221.881161 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 866 |    367.711695 |    259.251282 | Jagged Fang Designs                                                                                                                                                   |
| 867 |    970.764264 |    463.466016 | Tracy A. Heath                                                                                                                                                        |
| 868 |    454.945894 |    659.993940 | Matt Crook                                                                                                                                                            |
| 869 |    427.733014 |    765.704797 | Arthur S. Brum                                                                                                                                                        |
| 870 |    564.720377 |    765.170500 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 871 |    323.228241 |    263.133453 | NA                                                                                                                                                                    |
| 872 |    118.299053 |    344.125415 | Christoph Schomburg                                                                                                                                                   |
| 873 |    287.560233 |    503.617629 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 874 |    530.686583 |    309.451150 | Michael Scroggie                                                                                                                                                      |
| 875 |    955.425037 |    789.870483 | Oscar Sanisidro                                                                                                                                                       |
| 876 |   1011.292413 |    196.107520 | Melissa Broussard                                                                                                                                                     |
| 877 |    534.529409 |    111.650865 | Ferran Sayol                                                                                                                                                          |
| 878 |    818.252350 |    286.304128 | Scott Hartman                                                                                                                                                         |
| 879 |    445.448447 |    656.784313 | NA                                                                                                                                                                    |
| 880 |    215.994286 |    262.821192 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 881 |     30.229062 |    258.673852 | Gareth Monger                                                                                                                                                         |
| 882 |    176.405374 |    106.999349 | Zimices                                                                                                                                                               |
| 883 |    879.653837 |    117.949997 | C. Camilo Julián-Caballero                                                                                                                                            |
| 884 |    120.731089 |    332.396027 | Caleb M. Gordon                                                                                                                                                       |
| 885 |    716.375894 |    756.616692 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 886 |    240.050392 |    169.836424 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 887 |    789.010006 |    340.417379 | Matt Crook                                                                                                                                                            |
| 888 |    439.697471 |    738.923591 | Steven Traver                                                                                                                                                         |
| 889 |    182.551832 |    117.612440 | Gabriele Midolo                                                                                                                                                       |
| 890 |    198.997988 |    612.260912 | Gareth Monger                                                                                                                                                         |
| 891 |    596.794915 |    361.492789 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 892 |    688.970736 |    564.229755 | Margot Michaud                                                                                                                                                        |
| 893 |    932.602932 |    529.929325 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 894 |    286.579303 |    254.492892 | Yan Wong                                                                                                                                                              |
| 895 |    291.787078 |    287.868194 | Margot Michaud                                                                                                                                                        |
| 896 |    416.108642 |     81.042242 | Gareth Monger                                                                                                                                                         |
| 897 |    422.205558 |    111.442262 | Zimices                                                                                                                                                               |
| 898 |    891.955629 |    531.542271 | Juan Carlos Jerí                                                                                                                                                      |
| 899 |    335.084651 |    345.150847 | Kamil S. Jaron                                                                                                                                                        |
| 900 |    941.347105 |    723.599721 | Yan Wong                                                                                                                                                              |
| 901 |    444.107135 |    349.476751 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 902 |    522.105150 |     50.524850 | Zimices                                                                                                                                                               |
| 903 |    950.084132 |    191.222772 | Lisa Byrne                                                                                                                                                            |
| 904 |    348.309701 |    372.794455 | Andy Wilson                                                                                                                                                           |
| 905 |    334.823830 |    377.975500 | NA                                                                                                                                                                    |
| 906 |    497.449235 |    775.669124 | Ferran Sayol                                                                                                                                                          |
| 907 |    790.668474 |    410.113208 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 908 |     20.065947 |    557.686033 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 909 |     48.561361 |    279.189018 | Gareth Monger                                                                                                                                                         |
| 910 |    267.054532 |    365.196703 | Margot Michaud                                                                                                                                                        |
| 911 |    844.613829 |    170.934620 | Margot Michaud                                                                                                                                                        |
| 912 |    358.961335 |     62.978492 | Margot Michaud                                                                                                                                                        |
| 913 |    663.699336 |    122.860575 | Scott Hartman                                                                                                                                                         |
| 914 |    236.020384 |    560.038978 | Chris huh                                                                                                                                                             |
| 915 |    520.588496 |    102.135092 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                        |

    #> Your tweet has been posted!
