
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

Nobu Tamura and T. Michael Keesey, Matt Crook, Melissa Broussard, Beth
Reinke, Dmitry Bogdanov (vectorized by T. Michael Keesey), Ferran Sayol,
Yan Wong, Joe Schneid (vectorized by T. Michael Keesey), Zimices, Birgit
Lang, Nobu Tamura, vectorized by Zimices, Scott Hartman, Matt Wilkins,
Julio Garza, Jaime Headden, Dean Schnabel, Margot Michaud, Henry
Lydecker, Robbie N. Cada (vectorized by T. Michael Keesey), Roberto Díaz
Sibaja, Alex Slavenko, Dmitry Bogdanov (modified by T. Michael Keesey),
Tasman Dixon, Neil Kelley, DFoidl (vectorized by T. Michael Keesey),
Anthony Caravaggi, Gabriela Palomo-Munoz, Christoph Schomburg, Gabriele
Midolo, Aviceda (photo) & T. Michael Keesey, Evan Swigart (photography)
and T. Michael Keesey (vectorization), NASA, Noah Schlottman, Smokeybjb,
Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts,
Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Gareth Monger,
David Orr, Nobu Tamura (vectorized by T. Michael Keesey), Andy Wilson,
Xavier Giroux-Bougard, Steven Haddock • Jellywatch.org, Eduard Solà
(vectorized by T. Michael Keesey), Christine Axon, Renata F. Martins,
Chris huh, Jagged Fang Designs, Robert Gay, Shyamal, Cesar Julian,
Kanchi Nanjo, CNZdenek, Mathilde Cordellier, Allison Pease, Ingo
Braasch, Cristopher Silva, Maija Karala, Steven Traver, Peter Coxhead,
Matt Dempsey, Robbie N. Cada (modified by T. Michael Keesey), Tyler
Greenfield and Dean Schnabel, Kamil S. Jaron, Mathew Wedel, Crystal
Maier, Michelle Site, Becky Barnes, Skye McDavid, Danielle Alba, Mattia
Menchetti, Joanna Wolfe, T. Michael Keesey, Dmitry Bogdanov, Smokeybjb
(modified by Mike Keesey), Ville-Veikko Sinkkonen, Iain Reid, NOAA Great
Lakes Environmental Research Laboratory (illustration) and Timothy J.
Bartley (silhouette), Darius Nau, Alexander Schmidt-Lebuhn, Markus A.
Grohme, Ron Holmes/U. S. Fish and Wildlife Service (source photo), T.
Michael Keesey (vectorization), Matt Martyniuk (modified by T. Michael
Keesey), Kai R. Caspar, Andrew A. Farke, Natalie Claunch, Mali’o Kodis,
image from the Smithsonian Institution, Mathieu Basille, James I.
Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and
Jelle P. Wiersma (vectorized by T. Michael Keesey), Daniel Jaron,
Alexandre Vong, FunkMonk, Karla Martinez, Ignacio Contreras, Stanton F.
Fink (vectorized by T. Michael Keesey), Michele M Tobias, Obsidian Soul
(vectorized by T. Michael Keesey), C. Camilo Julián-Caballero, Lafage,
Gustav Mützel, Jakovche, Julia B McHugh, Brad McFeeters (vectorized by
T. Michael Keesey), Ellen Edmonson and Hugh Chrisp (vectorized by T.
Michael Keesey), Konsta Happonen, Juan Carlos Jerí, Chloé Schmidt,
Birgit Lang; based on a drawing by C.L. Koch, Erika Schumacher, Jessica
Anne Miller, Ghedoghedo (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Museum of Geology, University of Tartu, Pete
Buchholz, Joshua Fowler, Agnello Picorelli, Nobu Tamura, Liftarn, Sarah
Werning, Darren Naish (vectorized by T. Michael Keesey), Caleb M. Brown,
Sergio A. Muñoz-Gómez, Mali’o Kodis, photograph by John Slapcinsky,
Richard J. Harris, T. Michael Keesey (from a photo by Maximilian
Paradiz), Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Griensteidl and T.
Michael Keesey, Mariana Ruiz Villarreal, Hugo Gruson, Smokeybjb
(vectorized by T. Michael Keesey), Heinrich Harder (vectorized by
William Gearty), Don Armstrong, Chris A. Hamilton, Ernst Haeckel
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by “Wildcat
Dunny” (<http://www.flickr.com/people/wildcat_dunny/>), Ray Simpson
(vectorized by T. Michael Keesey), T. Michael Keesey (vector) and Stuart
Halliday (photograph), Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Frank
Denota, Terpsichores, Mali’o Kodis, drawing by Manvir Singh, Walter
Vladimir, Lukas Panzarin, Kent Elson Sorgon, Andreas Trepte (vectorized
by T. Michael Keesey), Jay Matternes (modified by T. Michael Keesey),
Nicholas J. Czaplewski, vectorized by Zimices, Sharon Wegner-Larsen,
Joseph J. W. Sertich, Mark A. Loewen, Nobu Tamura (modified by T.
Michael Keesey), SauropodomorphMonarch, Brian Swartz (vectorized by T.
Michael Keesey), Jim Bendon (photography) and T. Michael Keesey
(vectorization), James R. Spotila and Ray Chatterji, Harold N Eyster,
ДиБгд (vectorized by T. Michael Keesey), Michael Scroggie, Martin R.
Smith, after Skovsted et al 2015, Manabu Sakamoto, Matthew E. Clapham,
Carlos Cano-Barbacil, Robert Bruce Horsfall, vectorized by Zimices,
Tracy A. Heath, James Neenan, Rebecca Groom, Felix Vaux, Lukasiniho,
Martin Kevil, Maxime Dahirel, Todd Marshall, vectorized by Zimices,
Armin Reindl, Chuanixn Yu, Didier Descouens (vectorized by T. Michael
Keesey), 于川云, Matt Celeskey, Maky (vectorization), Gabriella Skollar
(photography), Rebecca Lewis (editing), Matt Martyniuk, Mark Miller, DW
Bapst (Modified from Bulman, 1964), T. Michael Keesey (vectorization)
and HuttyMcphoo (photography), Katie S. Collins, Conty (vectorized by T.
Michael Keesey), Mette Aumala, Dr. Thomas G. Barnes, USFWS, Ramona J
Heim, Chris Hay, Emily Willoughby, Danny Cicchetti (vectorized by T.
Michael Keesey), Noah Schlottman, photo by David J Patterson, Vanessa
Guerra, M Kolmann, T. Michael Keesey (vectorization) and Nadiatalent
(photography), Sidney Frederic Harmer, Arthur Everett Shipley
(vectorized by Maxime Dahirel), Hanyong Pu, Yoshitsugu Kobayashi,
Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia &
T. Michael Keesey, Sean McCann, Espen Horn (model; vectorized by T.
Michael Keesey from a photo by H. Zell), , Jose Carlos Arenas-Monroy,
Javier Luque & Sarah Gerken, Roule Jammes (vectorized by T. Michael
Keesey), Dave Angelini, Arthur S. Brum, Karl Ragnar Gjertsen (vectorized
by T. Michael Keesey), Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Nicolas
Mongiardino Koch, Noah Schlottman, photo by Casey Dunn, Theodore W.
Pietsch (photography) and T. Michael Keesey (vectorization), Hans
Hillewaert (vectorized by T. Michael Keesey), Apokryltaros (vectorized
by T. Michael Keesey), Scott Hartman, modified by T. Michael Keesey,
Nobu Tamura, modified by Andrew A. Farke, Duane Raver (vectorized by T.
Michael Keesey), Julien Louys, Collin Gross, Roberto Diaz Sibaja, based
on Domser, Inessa Voet, Eduard Solà Vázquez, vectorised by Yan Wong,
Mario Quevedo, Qiang Ou, Ian Burt (original) and T. Michael Keesey
(vectorization), Dann Pigdon, Auckland Museum, Aline M. Ghilardi, Doug
Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Daniel Stadtmauer, Tyler Greenfield, Bill Bouton (source
photo) & T. Michael Keesey (vectorization), Dein Freund der Baum
(vectorized by T. Michael Keesey), Duane Raver/USFWS, Steven Coombs,
Mali’o Kodis, image from the Biodiversity Heritage Library, Tauana J.
Cunha, Riccardo Percudani, Jonathan Wells, Stanton F. Fink, vectorized
by Zimices, Jake Warner, Owen Jones (derived from a CC-BY 2.0 photograph
by Paulo B. Chaves), Jack Mayer Wood, Jennifer Trimble, T. K. Robinson,
Antonov (vectorized by T. Michael Keesey), Servien (vectorized by T.
Michael Keesey), Kimberly Haddrell, Pearson Scott Foresman (vectorized
by T. Michael Keesey), Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Mo Hassan, Steven Coombs (vectorized by T. Michael Keesey), Elisabeth
Östman, Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., Caio Bernardes, vectorized by Zimices, Baheerathan
Murugavel, Anna Willoughby, Brockhaus and Efron, Mike Hanson, Ricardo
Araújo, Renato de Carvalho Ferreira, Original drawing by Nobu Tamura,
vectorized by Roberto Díaz Sibaja, Gabriel Lio, vectorized by Zimices,
Noah Schlottman, photo by Antonio Guillén, Scott Reid, \[unknown\], U.S.
Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Meliponicultor Itaymbere, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Ludwik Gąsiorowski, Óscar
San−Isidro (vectorized by T. Michael Keesey), Matt Wilkins (photo by
Patrick Kavanagh), Alan Manson (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Christopher Laumer (vectorized by T.
Michael Keesey), Joedison Rocha, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), FunkMonk
\[Michael B.H.\] (modified by T. Michael Keesey), DW Bapst (modified
from Mitchell 1990), Chase Brownstein, Dantheman9758 (vectorized by T.
Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    673.887372 |    294.387939 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
|   2 |    851.281670 |    317.731317 | Matt Crook                                                                                                                                                            |
|   3 |    667.392345 |    689.494243 | Melissa Broussard                                                                                                                                                     |
|   4 |    890.064448 |    586.027517 | Beth Reinke                                                                                                                                                           |
|   5 |    325.416734 |    431.499318 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|   6 |    241.331061 |    220.563638 | Ferran Sayol                                                                                                                                                          |
|   7 |    610.912983 |    112.456475 | Yan Wong                                                                                                                                                              |
|   8 |    514.795645 |    643.346970 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
|   9 |     73.676877 |    175.477949 | Zimices                                                                                                                                                               |
|  10 |    171.520768 |    666.034231 | Birgit Lang                                                                                                                                                           |
|  11 |    501.806988 |    513.064109 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  12 |    354.107907 |    509.386367 | Scott Hartman                                                                                                                                                         |
|  13 |    756.299111 |    493.415872 | Matt Crook                                                                                                                                                            |
|  14 |    617.089233 |    575.219329 | Matt Wilkins                                                                                                                                                          |
|  15 |    289.822290 |     37.175058 | Julio Garza                                                                                                                                                           |
|  16 |    172.422179 |    135.173684 | Zimices                                                                                                                                                               |
|  17 |    126.629911 |    284.484229 | Zimices                                                                                                                                                               |
|  18 |    431.914351 |    141.674502 | Matt Crook                                                                                                                                                            |
|  19 |    920.465037 |    461.447547 | Jaime Headden                                                                                                                                                         |
|  20 |    332.891303 |    737.842491 | Dean Schnabel                                                                                                                                                         |
|  21 |     76.574186 |    382.052334 | Margot Michaud                                                                                                                                                        |
|  22 |    162.634536 |    565.936749 | Matt Crook                                                                                                                                                            |
|  23 |    124.072877 |    744.575913 | NA                                                                                                                                                                    |
|  24 |    115.684070 |     18.844120 | Henry Lydecker                                                                                                                                                        |
|  25 |    778.114306 |    720.869535 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  26 |    521.623438 |    401.071335 | Roberto Díaz Sibaja                                                                                                                                                   |
|  27 |    352.461581 |    644.002378 | Alex Slavenko                                                                                                                                                         |
|  28 |    912.403934 |    189.573700 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
|  29 |    656.479878 |    432.515513 | NA                                                                                                                                                                    |
|  30 |    931.934911 |    757.348244 | Tasman Dixon                                                                                                                                                          |
|  31 |    202.945480 |    371.358187 | Neil Kelley                                                                                                                                                           |
|  32 |    953.948586 |    622.894514 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
|  33 |    532.732933 |    215.975804 | Alex Slavenko                                                                                                                                                         |
|  34 |    970.818434 |    362.495848 | Anthony Caravaggi                                                                                                                                                     |
|  35 |    916.608904 |     63.449514 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  36 |    654.127712 |    189.987163 | Christoph Schomburg                                                                                                                                                   |
|  37 |    481.210116 |    268.704600 | Gabriele Midolo                                                                                                                                                       |
|  38 |    767.593017 |    238.416182 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
|  39 |    325.948924 |    297.377401 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  40 |    586.809264 |    321.442971 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
|  41 |     52.089864 |    603.526091 | NASA                                                                                                                                                                  |
|  42 |    191.681917 |    450.876338 | Noah Schlottman                                                                                                                                                       |
|  43 |    434.828077 |    430.798988 | Smokeybjb                                                                                                                                                             |
|  44 |    788.756548 |     43.912737 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
|  45 |    748.258250 |    402.739518 | Gareth Monger                                                                                                                                                         |
|  46 |     76.338586 |    484.912469 | David Orr                                                                                                                                                             |
|  47 |    724.101997 |    579.093921 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  48 |    784.365389 |    645.691185 | Andy Wilson                                                                                                                                                           |
|  49 |    296.887921 |    141.965627 | Xavier Giroux-Bougard                                                                                                                                                 |
|  50 |    418.489641 |    312.983282 | Andy Wilson                                                                                                                                                           |
|  51 |    482.183480 |    722.307330 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|  52 |    818.784021 |    198.665186 | NA                                                                                                                                                                    |
|  53 |    338.374660 |     94.162380 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
|  54 |    682.463818 |    755.729921 | Christine Axon                                                                                                                                                        |
|  55 |    516.501570 |    563.368501 | Renata F. Martins                                                                                                                                                     |
|  56 |    543.704422 |    774.986989 | Chris huh                                                                                                                                                             |
|  57 |    444.972696 |     29.012590 | Jagged Fang Designs                                                                                                                                                   |
|  58 |     23.106305 |     79.064040 | Robert Gay                                                                                                                                                            |
|  59 |    646.969531 |     41.621971 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  60 |    119.788843 |     78.088337 | Scott Hartman                                                                                                                                                         |
|  61 |    951.654938 |    253.948064 | Ferran Sayol                                                                                                                                                          |
|  62 |    836.570249 |    392.020020 | Shyamal                                                                                                                                                               |
|  63 |    818.560401 |    117.073139 | Cesar Julian                                                                                                                                                          |
|  64 |    909.578142 |    706.968148 | Smokeybjb                                                                                                                                                             |
|  65 |    534.714931 |    261.987935 | Kanchi Nanjo                                                                                                                                                          |
|  66 |     62.240114 |    691.042204 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  67 |    120.492536 |    230.371065 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  68 |    961.247382 |    129.165347 | CNZdenek                                                                                                                                                              |
|  69 |    265.419253 |    559.963419 | Mathilde Cordellier                                                                                                                                                   |
|  70 |    558.726406 |    174.427419 | Tasman Dixon                                                                                                                                                          |
|  71 |    804.100322 |    750.988275 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  72 |    281.495358 |    380.135221 | Scott Hartman                                                                                                                                                         |
|  73 |    973.800668 |    687.487488 | Allison Pease                                                                                                                                                         |
|  74 |     19.205506 |    706.857951 | Ingo Braasch                                                                                                                                                          |
|  75 |    244.550479 |    507.707381 | Scott Hartman                                                                                                                                                         |
|  76 |    170.449976 |     46.723480 | Zimices                                                                                                                                                               |
|  77 |    714.862420 |    212.367364 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  78 |    887.583770 |    328.482579 | Jagged Fang Designs                                                                                                                                                   |
|  79 |    828.833317 |    419.239591 | Cristopher Silva                                                                                                                                                      |
|  80 |    789.992052 |    553.407617 | Zimices                                                                                                                                                               |
|  81 |    985.109766 |    573.852637 | Roberto Díaz Sibaja                                                                                                                                                   |
|  82 |    168.812792 |    709.206543 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  83 |    490.709035 |    156.089045 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  84 |    583.162351 |    703.974448 | Maija Karala                                                                                                                                                          |
|  85 |     62.331087 |    260.528836 | Margot Michaud                                                                                                                                                        |
|  86 |    597.198837 |    729.395222 | Steven Traver                                                                                                                                                         |
|  87 |     22.214806 |    544.745197 | Peter Coxhead                                                                                                                                                         |
|  88 |    991.169434 |    172.387057 | Christoph Schomburg                                                                                                                                                   |
|  89 |    432.342726 |    783.746291 | Margot Michaud                                                                                                                                                        |
|  90 |    150.961775 |    323.368349 | Matt Dempsey                                                                                                                                                          |
|  91 |    436.216937 |    234.599276 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
|  92 |    232.942111 |    294.448989 | NA                                                                                                                                                                    |
|  93 |    309.704726 |    228.347478 | Jagged Fang Designs                                                                                                                                                   |
|  94 |    375.727368 |    311.731564 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
|  95 |    211.150972 |    638.850743 | Kamil S. Jaron                                                                                                                                                        |
|  96 |    359.998078 |    353.065799 | NA                                                                                                                                                                    |
|  97 |    365.238916 |    333.293155 | Mathew Wedel                                                                                                                                                          |
|  98 |    541.527939 |    731.023802 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  99 |     72.123736 |    333.184183 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 100 |    673.422435 |     69.621503 | Dean Schnabel                                                                                                                                                         |
| 101 |    963.626498 |    191.589246 | Scott Hartman                                                                                                                                                         |
| 102 |    498.308213 |     25.337085 | Ferran Sayol                                                                                                                                                          |
| 103 |    997.333777 |    705.462219 | Crystal Maier                                                                                                                                                         |
| 104 |    631.058760 |    214.719032 | Michelle Site                                                                                                                                                         |
| 105 |    899.920709 |    414.160464 | Becky Barnes                                                                                                                                                          |
| 106 |    516.548314 |    465.425620 | Kamil S. Jaron                                                                                                                                                        |
| 107 |    789.068841 |    288.542405 | Skye McDavid                                                                                                                                                          |
| 108 |    691.146989 |    595.129436 | Danielle Alba                                                                                                                                                         |
| 109 |     27.899963 |    216.625532 | Mattia Menchetti                                                                                                                                                      |
| 110 |    570.479216 |     68.096974 | Steven Traver                                                                                                                                                         |
| 111 |    220.089341 |    664.750025 | Ferran Sayol                                                                                                                                                          |
| 112 |    304.955124 |    181.953259 | Joanna Wolfe                                                                                                                                                          |
| 113 |    453.011315 |     65.585621 | T. Michael Keesey                                                                                                                                                     |
| 114 |    796.417291 |    695.534658 | Xavier Giroux-Bougard                                                                                                                                                 |
| 115 |     25.272145 |    409.426348 | Dmitry Bogdanov                                                                                                                                                       |
| 116 |    246.538166 |    697.324995 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 117 |    472.319453 |    668.331631 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 118 |    534.307976 |    700.618726 | NA                                                                                                                                                                    |
| 119 |    869.601489 |    680.379653 | Ferran Sayol                                                                                                                                                          |
| 120 |    579.543539 |    473.166794 | Dmitry Bogdanov                                                                                                                                                       |
| 121 |    735.908268 |    127.025925 | Iain Reid                                                                                                                                                             |
| 122 |    193.586158 |    320.443665 | Tasman Dixon                                                                                                                                                          |
| 123 |    371.657063 |    430.106889 | Noah Schlottman                                                                                                                                                       |
| 124 |    884.036916 |      9.709271 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 125 |    957.910840 |    562.562646 | Margot Michaud                                                                                                                                                        |
| 126 |    515.782763 |    330.530860 | Margot Michaud                                                                                                                                                        |
| 127 |    977.785949 |    460.913821 | Darius Nau                                                                                                                                                            |
| 128 |    742.439012 |    370.774809 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 129 |    999.972296 |     77.346899 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 130 |     11.989534 |    395.079023 | Andy Wilson                                                                                                                                                           |
| 131 |    139.339558 |    159.348097 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 132 |     87.896504 |    192.299367 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
| 133 |    327.093468 |    189.224279 | Tasman Dixon                                                                                                                                                          |
| 134 |    751.277527 |    768.397667 | Markus A. Grohme                                                                                                                                                      |
| 135 |     68.380680 |    788.919603 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
| 136 |    211.231200 |    702.278629 | Andy Wilson                                                                                                                                                           |
| 137 |    229.761721 |    423.251838 | Margot Michaud                                                                                                                                                        |
| 138 |    190.908450 |    212.368394 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 139 |     94.742538 |     31.022725 | Steven Traver                                                                                                                                                         |
| 140 |    697.349303 |    228.356078 | Scott Hartman                                                                                                                                                         |
| 141 |    186.185981 |    191.071600 | Zimices                                                                                                                                                               |
| 142 |    737.061907 |    267.879013 | Joanna Wolfe                                                                                                                                                          |
| 143 |    754.963951 |    116.204249 | Ferran Sayol                                                                                                                                                          |
| 144 |    200.153076 |    777.499563 | Andy Wilson                                                                                                                                                           |
| 145 |    989.843245 |     46.163825 | Kai R. Caspar                                                                                                                                                         |
| 146 |     20.668232 |    277.414918 | T. Michael Keesey                                                                                                                                                     |
| 147 |     13.151094 |    651.329504 | Zimices                                                                                                                                                               |
| 148 |    444.676744 |    563.650008 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 149 |    669.258330 |    636.983956 | Andrew A. Farke                                                                                                                                                       |
| 150 |    952.260929 |    222.368819 | Darius Nau                                                                                                                                                            |
| 151 |    922.964511 |    640.580342 | T. Michael Keesey                                                                                                                                                     |
| 152 |    129.878261 |    337.016018 | Natalie Claunch                                                                                                                                                       |
| 153 |    546.336111 |    679.336885 | Skye McDavid                                                                                                                                                          |
| 154 |    673.971541 |    169.786394 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 155 |    470.255064 |    642.932545 | NA                                                                                                                                                                    |
| 156 |    210.708337 |     41.125929 | Mathieu Basille                                                                                                                                                       |
| 157 |    393.773465 |    707.065588 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 158 |    870.376803 |    561.053079 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 159 |     27.788359 |    321.539228 | Daniel Jaron                                                                                                                                                          |
| 160 |    555.741391 |     24.454035 | NA                                                                                                                                                                    |
| 161 |    200.869165 |    495.190067 | Zimices                                                                                                                                                               |
| 162 |    796.334392 |    217.759918 | Scott Hartman                                                                                                                                                         |
| 163 |    885.823708 |    248.558041 | Alexandre Vong                                                                                                                                                        |
| 164 |    450.706422 |    165.770721 | Margot Michaud                                                                                                                                                        |
| 165 |    630.702202 |    632.180424 | Margot Michaud                                                                                                                                                        |
| 166 |    840.202412 |    668.052451 | Ferran Sayol                                                                                                                                                          |
| 167 |    499.042468 |    313.992614 | Jagged Fang Designs                                                                                                                                                   |
| 168 |    994.693594 |     97.461168 | FunkMonk                                                                                                                                                              |
| 169 |    435.233337 |    255.747499 | Matt Crook                                                                                                                                                            |
| 170 |    750.695785 |     65.051073 | Karla Martinez                                                                                                                                                        |
| 171 |    654.236568 |    516.831666 | T. Michael Keesey                                                                                                                                                     |
| 172 |    857.544111 |    797.192443 | Chris huh                                                                                                                                                             |
| 173 |     82.367280 |    126.823565 | Scott Hartman                                                                                                                                                         |
| 174 |    740.137356 |    187.514269 | Gareth Monger                                                                                                                                                         |
| 175 |    814.594089 |    474.838240 | Markus A. Grohme                                                                                                                                                      |
| 176 |    589.418221 |    429.042708 | Ferran Sayol                                                                                                                                                          |
| 177 |    703.794058 |     17.299491 | NA                                                                                                                                                                    |
| 178 |    581.979968 |    682.316283 | Ignacio Contreras                                                                                                                                                     |
| 179 |    824.551621 |    439.685244 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 180 |    161.868559 |    431.052451 | Gareth Monger                                                                                                                                                         |
| 181 |     30.883869 |    783.252586 | Cesar Julian                                                                                                                                                          |
| 182 |    606.080831 |    275.414893 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 183 |    493.333366 |    326.040020 | Ferran Sayol                                                                                                                                                          |
| 184 |    502.072531 |    540.540752 | Margot Michaud                                                                                                                                                        |
| 185 |    841.800845 |    682.773115 | Michele M Tobias                                                                                                                                                      |
| 186 |    389.914890 |    361.078790 | Steven Traver                                                                                                                                                         |
| 187 |    412.090116 |    764.523215 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 188 |    992.447454 |    437.955066 | C. Camilo Julián-Caballero                                                                                                                                            |
| 189 |    245.606648 |     95.052193 | Renata F. Martins                                                                                                                                                     |
| 190 |    568.135291 |    531.294326 | Lafage                                                                                                                                                                |
| 191 |    702.065065 |     85.475577 | Margot Michaud                                                                                                                                                        |
| 192 |    250.587269 |    491.683462 | Matt Crook                                                                                                                                                            |
| 193 |    522.539115 |    372.634486 | Gustav Mützel                                                                                                                                                         |
| 194 |    777.164464 |    616.997621 | Jakovche                                                                                                                                                              |
| 195 |    393.036186 |    119.806943 | NA                                                                                                                                                                    |
| 196 |   1002.281727 |    660.668168 | Margot Michaud                                                                                                                                                        |
| 197 |    266.374280 |     92.368793 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 198 |    443.212990 |    764.942214 | Julia B McHugh                                                                                                                                                        |
| 199 |    461.162806 |    634.179020 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 200 |    739.565299 |    451.538172 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 201 |    772.601745 |     84.187303 | Scott Hartman                                                                                                                                                         |
| 202 |    443.785714 |    406.766719 | Markus A. Grohme                                                                                                                                                      |
| 203 |    571.068585 |    625.053836 | Konsta Happonen                                                                                                                                                       |
| 204 |    801.962396 |    336.771506 | Kai R. Caspar                                                                                                                                                         |
| 205 |     99.772309 |    440.338522 | Ferran Sayol                                                                                                                                                          |
| 206 |    662.754064 |    210.127079 | Gareth Monger                                                                                                                                                         |
| 207 |    383.287892 |    584.201951 | Juan Carlos Jerí                                                                                                                                                      |
| 208 |    340.353743 |    669.685271 | Zimices                                                                                                                                                               |
| 209 |    450.602535 |    476.305614 | Zimices                                                                                                                                                               |
| 210 |    782.824823 |    774.445441 | T. Michael Keesey                                                                                                                                                     |
| 211 |   1016.918683 |    647.017105 | Chloé Schmidt                                                                                                                                                         |
| 212 |    694.976121 |    632.385384 | Ferran Sayol                                                                                                                                                          |
| 213 |    229.738665 |    783.051374 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                          |
| 214 |    389.229657 |    749.335864 | NA                                                                                                                                                                    |
| 215 |    218.416959 |    322.523618 | Gareth Monger                                                                                                                                                         |
| 216 |    368.634226 |    200.632629 | Andrew A. Farke                                                                                                                                                       |
| 217 |     54.538963 |    130.568764 | NA                                                                                                                                                                    |
| 218 |    230.695490 |    553.995579 | Alexandre Vong                                                                                                                                                        |
| 219 |   1011.825406 |    586.300135 | Karla Martinez                                                                                                                                                        |
| 220 |    363.298867 |    771.458523 | Mathew Wedel                                                                                                                                                          |
| 221 |    428.406994 |    578.766009 | C. Camilo Julián-Caballero                                                                                                                                            |
| 222 |    600.802951 |    447.402694 | Zimices                                                                                                                                                               |
| 223 |     24.353243 |    654.258834 | Erika Schumacher                                                                                                                                                      |
| 224 |    751.692220 |    276.625311 | Beth Reinke                                                                                                                                                           |
| 225 |    501.270670 |    551.485271 | Scott Hartman                                                                                                                                                         |
| 226 |    511.001753 |    241.800369 | T. Michael Keesey                                                                                                                                                     |
| 227 |     31.654361 |    284.930198 | Andy Wilson                                                                                                                                                           |
| 228 |    515.807146 |     83.771313 | Matt Crook                                                                                                                                                            |
| 229 |     45.947920 |     60.071591 | Jessica Anne Miller                                                                                                                                                   |
| 230 |    399.444846 |    133.284160 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 231 |    495.691438 |    455.866521 | FunkMonk                                                                                                                                                              |
| 232 |     83.025563 |    592.377014 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 233 |    186.382618 |    151.787292 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 234 |    413.642406 |    566.824784 | Pete Buchholz                                                                                                                                                         |
| 235 |    588.347112 |    721.767437 | Jagged Fang Designs                                                                                                                                                   |
| 236 |    468.004760 |     46.447571 | Joshua Fowler                                                                                                                                                         |
| 237 |     26.045270 |    496.658238 | Beth Reinke                                                                                                                                                           |
| 238 |    727.648640 |    164.626967 | T. Michael Keesey                                                                                                                                                     |
| 239 |    467.899067 |    464.541792 | NA                                                                                                                                                                    |
| 240 |    415.011565 |    455.558252 | Maija Karala                                                                                                                                                          |
| 241 |    805.658894 |      9.672316 | Agnello Picorelli                                                                                                                                                     |
| 242 |    988.063427 |    592.085302 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 243 |    908.971567 |    365.905941 | Gareth Monger                                                                                                                                                         |
| 244 |   1008.921126 |     65.127689 | Nobu Tamura                                                                                                                                                           |
| 245 |    823.309494 |     88.333739 | Margot Michaud                                                                                                                                                        |
| 246 |    170.019617 |    297.742255 | Liftarn                                                                                                                                                               |
| 247 |    235.333470 |    415.458737 | Gareth Monger                                                                                                                                                         |
| 248 |    788.424623 |    680.847367 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 249 |    396.703559 |    220.191985 | Andrew A. Farke                                                                                                                                                       |
| 250 |    844.331632 |    490.342804 | Sarah Werning                                                                                                                                                         |
| 251 |    532.894746 |    312.846790 | Zimices                                                                                                                                                               |
| 252 |    685.838335 |    505.130182 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 253 |    565.114223 |    740.913403 | Gareth Monger                                                                                                                                                         |
| 254 |    586.098351 |    765.287974 | T. Michael Keesey                                                                                                                                                     |
| 255 |    745.530630 |    353.446770 | Caleb M. Brown                                                                                                                                                        |
| 256 |    875.615692 |    376.475676 | Markus A. Grohme                                                                                                                                                      |
| 257 |    404.929612 |    565.304464 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 258 |    198.038794 |    104.051117 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 259 |    824.519960 |     78.988054 | Maija Karala                                                                                                                                                          |
| 260 |    369.078238 |    789.484060 | Dean Schnabel                                                                                                                                                         |
| 261 |    892.456169 |     92.851395 | T. Michael Keesey                                                                                                                                                     |
| 262 |    858.170191 |    240.498278 | Richard J. Harris                                                                                                                                                     |
| 263 |    812.529108 |    307.620492 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 264 |    732.866884 |    111.117075 | Andy Wilson                                                                                                                                                           |
| 265 |     71.952633 |    555.179283 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 266 |    307.976395 |    575.991256 | NA                                                                                                                                                                    |
| 267 |     11.457030 |    251.216952 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 268 |    270.578089 |    496.408675 | Dean Schnabel                                                                                                                                                         |
| 269 |    276.330806 |    315.916552 | Tasman Dixon                                                                                                                                                          |
| 270 |    298.433051 |    783.447746 | Agnello Picorelli                                                                                                                                                     |
| 271 |    758.427147 |     90.595738 | Jagged Fang Designs                                                                                                                                                   |
| 272 |    468.246327 |    344.688380 | Birgit Lang                                                                                                                                                           |
| 273 |    701.874062 |    732.614819 | Tasman Dixon                                                                                                                                                          |
| 274 |    760.288232 |    692.920689 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 275 |    936.791080 |    572.142503 | Margot Michaud                                                                                                                                                        |
| 276 |    699.708036 |      3.161652 | Jagged Fang Designs                                                                                                                                                   |
| 277 |    210.558681 |     12.063835 | Kamil S. Jaron                                                                                                                                                        |
| 278 |    360.606807 |     47.802365 | Gareth Monger                                                                                                                                                         |
| 279 |    724.453776 |    618.913207 | Gareth Monger                                                                                                                                                         |
| 280 |    326.736934 |    230.423244 | David Orr                                                                                                                                                             |
| 281 |    178.008894 |     29.751570 | Markus A. Grohme                                                                                                                                                      |
| 282 |    828.409055 |    486.009316 | NA                                                                                                                                                                    |
| 283 |    159.264665 |    242.863801 | Margot Michaud                                                                                                                                                        |
| 284 |    561.216072 |    720.565202 | Steven Traver                                                                                                                                                         |
| 285 |   1010.979118 |    507.922576 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 286 |    389.252962 |    252.287964 | Mariana Ruiz Villarreal                                                                                                                                               |
| 287 |     89.265268 |    786.235911 | Hugo Gruson                                                                                                                                                           |
| 288 |    589.770889 |    386.045064 | NA                                                                                                                                                                    |
| 289 |    615.318226 |    780.091864 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 290 |    410.671629 |    393.362390 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 291 |    888.090689 |    135.863683 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 292 |    974.343047 |    334.483811 | Crystal Maier                                                                                                                                                         |
| 293 |    155.797319 |    634.707469 | Matt Crook                                                                                                                                                            |
| 294 |     73.428658 |    193.571012 | Don Armstrong                                                                                                                                                         |
| 295 |    192.177211 |      9.603122 | Birgit Lang                                                                                                                                                           |
| 296 |   1004.879201 |    462.921045 | Chris huh                                                                                                                                                             |
| 297 |    185.806150 |     70.735256 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 298 |    431.030444 |    199.856314 | Margot Michaud                                                                                                                                                        |
| 299 |    293.770717 |    206.946339 | Chris A. Hamilton                                                                                                                                                     |
| 300 |    155.306677 |     51.051323 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 301 |    392.460752 |    272.068742 | Gabriele Midolo                                                                                                                                                       |
| 302 |    767.089854 |    154.720245 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 303 |     35.772500 |    765.638369 | FunkMonk                                                                                                                                                              |
| 304 |     17.430228 |    620.498920 | Scott Hartman                                                                                                                                                         |
| 305 |     29.512909 |    377.401641 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 306 |    795.116490 |    738.302328 | Smokeybjb                                                                                                                                                             |
| 307 |    127.859703 |    438.946260 | Gareth Monger                                                                                                                                                         |
| 308 |    647.310873 |    358.671593 | Scott Hartman                                                                                                                                                         |
| 309 |    639.100931 |    523.772577 | Kai R. Caspar                                                                                                                                                         |
| 310 |    571.953215 |    245.405788 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 311 |    923.555792 |    389.717463 | Julia B McHugh                                                                                                                                                        |
| 312 |    202.838446 |    245.758446 | Birgit Lang                                                                                                                                                           |
| 313 |    679.747762 |    236.418846 | Darius Nau                                                                                                                                                            |
| 314 |     96.674615 |    455.369458 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                               |
| 315 |    713.684186 |    359.737684 | Frank Denota                                                                                                                                                          |
| 316 |    637.826897 |    321.505808 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 317 |     90.768187 |    531.612274 | Terpsichores                                                                                                                                                          |
| 318 |    648.260231 |    545.667241 | Maija Karala                                                                                                                                                          |
| 319 |    847.994374 |    202.101784 | Noah Schlottman                                                                                                                                                       |
| 320 |    330.046251 |    167.941804 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 321 |    714.791090 |     85.915897 | Steven Traver                                                                                                                                                         |
| 322 |    458.397943 |    386.271201 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 323 |     29.259383 |    645.364516 | Walter Vladimir                                                                                                                                                       |
| 324 |     13.415309 |    383.557521 | Lukas Panzarin                                                                                                                                                        |
| 325 |    493.963302 |    350.292004 | Kent Elson Sorgon                                                                                                                                                     |
| 326 |    714.143288 |     44.363808 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 327 |    827.683649 |    312.933224 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                         |
| 328 |    697.642535 |    362.361293 | Zimices                                                                                                                                                               |
| 329 |    544.662305 |    433.690499 | Chris huh                                                                                                                                                             |
| 330 |    769.297173 |    670.989228 | T. Michael Keesey                                                                                                                                                     |
| 331 |    379.601429 |    370.847493 | NA                                                                                                                                                                    |
| 332 |    789.525537 |    497.813326 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 333 |    333.176448 |    576.094124 | T. Michael Keesey                                                                                                                                                     |
| 334 |    720.448642 |    136.955267 | Matt Crook                                                                                                                                                            |
| 335 |    543.324466 |    151.952743 | Sharon Wegner-Larsen                                                                                                                                                  |
| 336 |     46.584792 |    294.706298 | Zimices                                                                                                                                                               |
| 337 |    471.586055 |    406.353174 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 338 |     17.486091 |    507.712836 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 339 |     44.149509 |     10.954802 | Ferran Sayol                                                                                                                                                          |
| 340 |    133.818607 |    504.308779 | Tasman Dixon                                                                                                                                                          |
| 341 |    852.045433 |     90.041672 | SauropodomorphMonarch                                                                                                                                                 |
| 342 |    258.960662 |    786.241070 | Chris huh                                                                                                                                                             |
| 343 |    493.084170 |    374.022546 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                        |
| 344 |    416.544387 |      8.473988 | Michelle Site                                                                                                                                                         |
| 345 |     66.324302 |     56.097561 | Ferran Sayol                                                                                                                                                          |
| 346 |    311.696427 |    533.538247 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 347 |     16.758152 |    428.050181 | Andy Wilson                                                                                                                                                           |
| 348 |    348.424839 |    205.261843 | Matt Crook                                                                                                                                                            |
| 349 |    492.164342 |    147.803384 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 350 |    699.526514 |    645.273437 | Zimices                                                                                                                                                               |
| 351 |    176.655564 |      6.763921 | Harold N Eyster                                                                                                                                                       |
| 352 |    989.882784 |    206.724366 | Terpsichores                                                                                                                                                          |
| 353 |    607.434922 |    660.430936 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 354 |    851.301434 |    782.608726 | Scott Hartman                                                                                                                                                         |
| 355 |    243.581805 |     84.208366 | Erika Schumacher                                                                                                                                                      |
| 356 |    265.644029 |    109.989480 | Sharon Wegner-Larsen                                                                                                                                                  |
| 357 |    644.552117 |    559.383889 | Michael Scroggie                                                                                                                                                      |
| 358 |    553.897867 |    641.862556 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 359 |     99.390464 |    108.785059 | Mathilde Cordellier                                                                                                                                                   |
| 360 |    271.840076 |    321.308609 | Jagged Fang Designs                                                                                                                                                   |
| 361 |    857.055247 |    285.038340 | Gareth Monger                                                                                                                                                         |
| 362 |    226.674905 |    615.014701 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 363 |    898.903007 |    157.857309 | Jagged Fang Designs                                                                                                                                                   |
| 364 |    743.166694 |    313.679088 | NA                                                                                                                                                                    |
| 365 |    334.274031 |    683.138540 | Manabu Sakamoto                                                                                                                                                       |
| 366 |    433.337933 |    592.700457 | Zimices                                                                                                                                                               |
| 367 |    295.115972 |    697.546364 | Matthew E. Clapham                                                                                                                                                    |
| 368 |     43.207412 |     42.660015 | Ferran Sayol                                                                                                                                                          |
| 369 |    187.958465 |     96.472910 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 370 |    936.503385 |    654.276811 | Ferran Sayol                                                                                                                                                          |
| 371 |    731.581761 |    231.710159 | Tasman Dixon                                                                                                                                                          |
| 372 |    919.544168 |    324.601839 | FunkMonk                                                                                                                                                              |
| 373 |    801.100446 |    771.081910 | Matt Crook                                                                                                                                                            |
| 374 |    426.165203 |    377.399781 | Zimices                                                                                                                                                               |
| 375 |    772.958417 |     97.223918 | Kai R. Caspar                                                                                                                                                         |
| 376 |    610.601929 |    148.482152 | Margot Michaud                                                                                                                                                        |
| 377 |    176.127884 |    647.481438 | Jagged Fang Designs                                                                                                                                                   |
| 378 |    372.542753 |    410.225930 | Pete Buchholz                                                                                                                                                         |
| 379 |    880.810919 |    600.237560 | Beth Reinke                                                                                                                                                           |
| 380 |    409.660024 |    109.314105 | Carlos Cano-Barbacil                                                                                                                                                  |
| 381 |    723.177142 |    422.285669 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 382 |    391.963122 |    700.740670 | Scott Hartman                                                                                                                                                         |
| 383 |    108.991961 |    639.070784 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 384 |    408.247800 |    740.234196 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 385 |    801.093514 |    505.515183 | Zimices                                                                                                                                                               |
| 386 |    290.550825 |    334.366084 | Tracy A. Heath                                                                                                                                                        |
| 387 |     78.042823 |     36.147714 | Zimices                                                                                                                                                               |
| 388 |    595.814953 |     12.393350 | Jagged Fang Designs                                                                                                                                                   |
| 389 |    230.275024 |     65.312277 | James Neenan                                                                                                                                                          |
| 390 |    431.372028 |    275.953164 | Sarah Werning                                                                                                                                                         |
| 391 |   1005.123039 |    518.845127 | Kanchi Nanjo                                                                                                                                                          |
| 392 |    965.493216 |    713.963160 | Gareth Monger                                                                                                                                                         |
| 393 |    171.473406 |    317.499160 | Michelle Site                                                                                                                                                         |
| 394 |   1008.260446 |    282.904217 | Kai R. Caspar                                                                                                                                                         |
| 395 |    945.845719 |    154.461375 | Rebecca Groom                                                                                                                                                         |
| 396 |    253.349745 |    311.860110 | Erika Schumacher                                                                                                                                                      |
| 397 |    242.065387 |    597.311353 | T. Michael Keesey                                                                                                                                                     |
| 398 |      8.096305 |    474.210405 | Zimices                                                                                                                                                               |
| 399 |    348.722908 |    780.208111 | Matt Crook                                                                                                                                                            |
| 400 |    985.754036 |    654.478688 | Steven Traver                                                                                                                                                         |
| 401 |    445.142829 |    380.899219 | Felix Vaux                                                                                                                                                            |
| 402 |    555.479269 |     76.630743 | Lukasiniho                                                                                                                                                            |
| 403 |    179.305514 |     34.609768 | Martin Kevil                                                                                                                                                          |
| 404 |    827.618280 |    373.027133 | Matt Crook                                                                                                                                                            |
| 405 |    112.227889 |    422.368698 | Zimices                                                                                                                                                               |
| 406 |    188.286228 |    169.126309 | Chris huh                                                                                                                                                             |
| 407 |    864.034501 |     76.719625 | Zimices                                                                                                                                                               |
| 408 |    479.953633 |    757.594693 | Maxime Dahirel                                                                                                                                                        |
| 409 |    741.788863 |    156.306193 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 410 |    600.813348 |    631.217064 | Juan Carlos Jerí                                                                                                                                                      |
| 411 |    501.552138 |     76.717428 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 412 |    661.190372 |    231.151733 | Birgit Lang                                                                                                                                                           |
| 413 |    347.036412 |    160.377209 | T. Michael Keesey                                                                                                                                                     |
| 414 |    857.149612 |    722.408845 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 415 |   1011.887015 |    235.002242 | Tasman Dixon                                                                                                                                                          |
| 416 |    646.476039 |    349.185749 | Jagged Fang Designs                                                                                                                                                   |
| 417 |   1014.953639 |    346.214712 | Jagged Fang Designs                                                                                                                                                   |
| 418 |    986.083089 |    782.934003 | T. Michael Keesey                                                                                                                                                     |
| 419 |    797.728235 |    673.594767 | Margot Michaud                                                                                                                                                        |
| 420 |    953.441245 |    232.633630 | Mathilde Cordellier                                                                                                                                                   |
| 421 |    319.106620 |    682.532217 | Andy Wilson                                                                                                                                                           |
| 422 |    605.403558 |     42.771586 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 423 |    716.981284 |    189.854397 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 424 |    232.553929 |    754.665832 | Dean Schnabel                                                                                                                                                         |
| 425 |    358.371740 |    446.857989 | Zimices                                                                                                                                                               |
| 426 |    986.691502 |    763.650614 | Matt Crook                                                                                                                                                            |
| 427 |     58.496243 |     12.491014 | Armin Reindl                                                                                                                                                          |
| 428 |    855.190323 |    711.947456 | Ingo Braasch                                                                                                                                                          |
| 429 |    736.793921 |     93.233245 | Scott Hartman                                                                                                                                                         |
| 430 |    269.318659 |    690.202280 | Matt Crook                                                                                                                                                            |
| 431 |     82.096173 |    115.615899 | Gareth Monger                                                                                                                                                         |
| 432 |    470.750746 |    622.437540 | Tasman Dixon                                                                                                                                                          |
| 433 |    125.304034 |     49.420774 | Jagged Fang Designs                                                                                                                                                   |
| 434 |    625.125256 |    228.191908 | Gareth Monger                                                                                                                                                         |
| 435 |    744.718526 |    674.515353 | Zimices                                                                                                                                                               |
| 436 |    863.522106 |    510.881087 | NA                                                                                                                                                                    |
| 437 |    785.071006 |    522.772166 | Matt Crook                                                                                                                                                            |
| 438 |    619.601099 |    769.563364 | Chuanixn Yu                                                                                                                                                           |
| 439 |    521.148212 |     27.109581 | T. Michael Keesey                                                                                                                                                     |
| 440 |    987.456016 |    676.647786 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 441 |    422.569570 |     76.247511 | Jagged Fang Designs                                                                                                                                                   |
| 442 |    411.587721 |    502.694874 | 于川云                                                                                                                                                                   |
| 443 |    851.376532 |    265.880513 | Matt Celeskey                                                                                                                                                         |
| 444 |    331.570799 |    128.547783 | Michelle Site                                                                                                                                                         |
| 445 |    115.667969 |    455.839857 | Matt Crook                                                                                                                                                            |
| 446 |    677.055220 |    576.451622 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                        |
| 447 |    890.173374 |    315.980221 | T. Michael Keesey                                                                                                                                                     |
| 448 |    573.623649 |    793.992048 | Carlos Cano-Barbacil                                                                                                                                                  |
| 449 |    473.522100 |    569.979754 | Christoph Schomburg                                                                                                                                                   |
| 450 |    140.014716 |     53.927638 | Jagged Fang Designs                                                                                                                                                   |
| 451 |    288.536710 |    523.532426 | Matt Martyniuk                                                                                                                                                        |
| 452 |    677.808976 |    327.375100 | Mark Miller                                                                                                                                                           |
| 453 |    388.060331 |    770.008698 | Pete Buchholz                                                                                                                                                         |
| 454 |    624.645518 |     85.600168 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 455 |    575.773274 |    268.878405 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 456 |    627.550720 |    504.899575 | Ferran Sayol                                                                                                                                                          |
| 457 |    801.645975 |    786.492423 | Alex Slavenko                                                                                                                                                         |
| 458 |    514.674126 |    364.535659 | Sarah Werning                                                                                                                                                         |
| 459 |    666.743819 |    498.008787 | Markus A. Grohme                                                                                                                                                      |
| 460 |     54.577678 |     75.928148 | Alexandre Vong                                                                                                                                                        |
| 461 |    444.987865 |    351.302325 | Matt Crook                                                                                                                                                            |
| 462 |    732.667216 |    698.112573 | Margot Michaud                                                                                                                                                        |
| 463 |    326.138621 |    476.490503 | NA                                                                                                                                                                    |
| 464 |    520.529503 |     43.566508 | Katie S. Collins                                                                                                                                                      |
| 465 |    398.838604 |    508.437615 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 466 |   1011.714136 |    767.397665 | Jagged Fang Designs                                                                                                                                                   |
| 467 |    263.564686 |    289.248428 | Mette Aumala                                                                                                                                                          |
| 468 |     19.560246 |    579.353078 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 469 |    474.694889 |    721.620143 | Michele M Tobias                                                                                                                                                      |
| 470 |    526.184738 |     13.014273 | Ramona J Heim                                                                                                                                                         |
| 471 |    883.395970 |    153.854127 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 472 |   1002.530234 |    499.233591 | Yan Wong                                                                                                                                                              |
| 473 |    613.643626 |    758.376292 | Zimices                                                                                                                                                               |
| 474 |    730.542823 |     22.777166 | Matt Crook                                                                                                                                                            |
| 475 |    794.467077 |    194.700925 | Chris Hay                                                                                                                                                             |
| 476 |    904.095426 |    313.127868 | C. Camilo Julián-Caballero                                                                                                                                            |
| 477 |    786.480568 |    443.001373 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 478 |    125.131110 |    627.949300 | Matt Crook                                                                                                                                                            |
| 479 |    358.947599 |    794.868159 | Emily Willoughby                                                                                                                                                      |
| 480 |    605.126612 |     57.078891 | Matt Crook                                                                                                                                                            |
| 481 |    766.563783 |    363.188005 | Chris huh                                                                                                                                                             |
| 482 |    144.606120 |    506.995246 | Matt Crook                                                                                                                                                            |
| 483 |    769.846646 |    335.787689 | Margot Michaud                                                                                                                                                        |
| 484 |     84.019265 |    562.796144 | Gareth Monger                                                                                                                                                         |
| 485 |    244.144486 |    733.438881 | Steven Traver                                                                                                                                                         |
| 486 |    693.378608 |     64.685357 | Birgit Lang                                                                                                                                                           |
| 487 |    588.806609 |    792.757582 | Scott Hartman                                                                                                                                                         |
| 488 |    360.457892 |    578.209061 | FunkMonk                                                                                                                                                              |
| 489 |     27.818101 |    253.581964 | Matt Crook                                                                                                                                                            |
| 490 |    576.220086 |    668.925639 | Steven Traver                                                                                                                                                         |
| 491 |    247.458303 |    469.769866 | Markus A. Grohme                                                                                                                                                      |
| 492 |     14.057549 |    602.744256 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 493 |    816.403384 |    459.099093 | Scott Hartman                                                                                                                                                         |
| 494 |    951.746725 |    165.528239 | Matt Crook                                                                                                                                                            |
| 495 |    403.491875 |    552.304182 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 496 |    529.906155 |    182.434618 | Margot Michaud                                                                                                                                                        |
| 497 |    590.985260 |    670.729484 | Zimices                                                                                                                                                               |
| 498 |    570.650345 |    456.976644 | Zimices                                                                                                                                                               |
| 499 |    395.581852 |    530.443744 | Michelle Site                                                                                                                                                         |
| 500 |    890.358195 |    568.979543 | Matt Crook                                                                                                                                                            |
| 501 |    203.378937 |    235.461666 | Gareth Monger                                                                                                                                                         |
| 502 |     88.864011 |    624.653935 | Zimices                                                                                                                                                               |
| 503 |    530.215930 |    645.848866 | Vanessa Guerra                                                                                                                                                        |
| 504 |    176.370581 |    634.723735 | M Kolmann                                                                                                                                                             |
| 505 |     10.432276 |    778.582703 | Gareth Monger                                                                                                                                                         |
| 506 |    710.012990 |    710.575949 | NA                                                                                                                                                                    |
| 507 |    506.064233 |    327.133767 | M Kolmann                                                                                                                                                             |
| 508 |     51.766699 |    243.151662 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 509 |    605.137941 |    409.052551 | Gareth Monger                                                                                                                                                         |
| 510 |    109.907119 |    614.850644 | Birgit Lang                                                                                                                                                           |
| 511 |    536.858718 |    340.914652 | Alexandre Vong                                                                                                                                                        |
| 512 |    104.860924 |     50.214528 | Zimices                                                                                                                                                               |
| 513 |    768.557709 |    320.276474 | Matt Crook                                                                                                                                                            |
| 514 |    177.157144 |    300.649288 | Matt Crook                                                                                                                                                            |
| 515 |    752.780348 |    322.047329 | T. Michael Keesey                                                                                                                                                     |
| 516 |    838.681632 |     69.063257 | Ferran Sayol                                                                                                                                                          |
| 517 |    411.325995 |     93.354492 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 518 |    513.584797 |    303.933269 | NA                                                                                                                                                                    |
| 519 |    871.170979 |     86.753550 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 520 |    472.405795 |    613.847626 | NA                                                                                                                                                                    |
| 521 |    479.338116 |    733.039580 | Sean McCann                                                                                                                                                           |
| 522 |     66.845905 |    108.177497 | Margot Michaud                                                                                                                                                        |
| 523 |    340.626834 |    109.430537 | NA                                                                                                                                                                    |
| 524 |    386.108334 |     17.619244 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 525 |    131.395171 |    695.144408 | Jagged Fang Designs                                                                                                                                                   |
| 526 |      8.229646 |    263.083713 | Harold N Eyster                                                                                                                                                       |
| 527 |    254.409744 |    329.884435 | Rebecca Groom                                                                                                                                                         |
| 528 |    656.539737 |    159.310707 | NA                                                                                                                                                                    |
| 529 |    626.649195 |    752.934578 | Kai R. Caspar                                                                                                                                                         |
| 530 |    364.204675 |    365.775480 |                                                                                                                                                                       |
| 531 |    812.036444 |    492.046101 | Margot Michaud                                                                                                                                                        |
| 532 |    596.172116 |     68.172798 | NA                                                                                                                                                                    |
| 533 |    107.773073 |    699.051971 | Erika Schumacher                                                                                                                                                      |
| 534 |    188.644141 |    289.598445 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 535 |    879.045847 |    499.342969 | Christoph Schomburg                                                                                                                                                   |
| 536 |    589.109489 |    507.763823 | Chris huh                                                                                                                                                             |
| 537 |    481.642944 |     91.705259 | Margot Michaud                                                                                                                                                        |
| 538 |   1001.462448 |    265.940487 | NA                                                                                                                                                                    |
| 539 |    868.887024 |    487.811453 | Steven Traver                                                                                                                                                         |
| 540 |    193.153238 |    707.399167 | Javier Luque & Sarah Gerken                                                                                                                                           |
| 541 |    147.131161 |    393.343396 | Iain Reid                                                                                                                                                             |
| 542 |    163.245619 |    785.932975 | Ferran Sayol                                                                                                                                                          |
| 543 |    250.368907 |    779.513447 | Scott Hartman                                                                                                                                                         |
| 544 |     57.267261 |    534.499342 | Michelle Site                                                                                                                                                         |
| 545 |    910.356622 |    591.072687 | Michael Scroggie                                                                                                                                                      |
| 546 |    793.862306 |    622.370787 | Steven Traver                                                                                                                                                         |
| 547 |    563.039986 |    235.330802 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                        |
| 548 |     96.162105 |    140.960744 | Rebecca Groom                                                                                                                                                         |
| 549 |    426.357325 |    604.715348 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 550 |    510.780107 |    148.083189 | Margot Michaud                                                                                                                                                        |
| 551 |    951.315205 |    685.030877 | Chris huh                                                                                                                                                             |
| 552 |    555.722230 |    465.854032 | Scott Hartman                                                                                                                                                         |
| 553 |    987.906363 |    530.485357 | Steven Traver                                                                                                                                                         |
| 554 |    815.484001 |    767.379538 | Dave Angelini                                                                                                                                                         |
| 555 |    466.976269 |    313.351048 | Beth Reinke                                                                                                                                                           |
| 556 |    294.312099 |    365.036098 | Scott Hartman                                                                                                                                                         |
| 557 |   1011.479778 |    428.409514 | Birgit Lang                                                                                                                                                           |
| 558 |    584.392145 |    257.284603 | Arthur S. Brum                                                                                                                                                        |
| 559 |    554.806684 |      5.360933 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 560 |    741.244885 |    603.592208 | Tasman Dixon                                                                                                                                                          |
| 561 |    249.605009 |    384.936989 | Matt Crook                                                                                                                                                            |
| 562 |    362.727454 |    119.185514 | Harold N Eyster                                                                                                                                                       |
| 563 |   1003.869010 |    250.391017 | Anthony Caravaggi                                                                                                                                                     |
| 564 |    434.706183 |    498.967730 | Henry Lydecker                                                                                                                                                        |
| 565 |    883.814358 |    641.299070 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 566 |    132.735597 |    489.991591 | Margot Michaud                                                                                                                                                        |
| 567 |    698.475213 |    444.756135 | Nicolas Mongiardino Koch                                                                                                                                              |
| 568 |     35.440122 |    186.697009 | NA                                                                                                                                                                    |
| 569 |    211.365201 |    350.017785 | Gareth Monger                                                                                                                                                         |
| 570 |    234.728827 |     52.996591 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 571 |    440.348367 |     82.554431 | Smokeybjb                                                                                                                                                             |
| 572 |    617.076269 |    613.785183 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 573 |    784.176385 |    187.678399 | Steven Traver                                                                                                                                                         |
| 574 |    877.342777 |    138.688858 | Andrew A. Farke                                                                                                                                                       |
| 575 |    919.023598 |      5.303240 | Chris huh                                                                                                                                                             |
| 576 |    537.882739 |    482.413973 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 577 |    982.691116 |    481.586596 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 578 |    937.821741 |    467.689220 | Zimices                                                                                                                                                               |
| 579 |    453.977801 |    689.629831 | NA                                                                                                                                                                    |
| 580 |    475.827331 |    792.156211 | Michael Scroggie                                                                                                                                                      |
| 581 |    411.031895 |     64.226513 | Xavier Giroux-Bougard                                                                                                                                                 |
| 582 |    266.758924 |    770.807499 | Chuanixn Yu                                                                                                                                                           |
| 583 |    496.071376 |     99.886988 | Ferran Sayol                                                                                                                                                          |
| 584 |    424.852823 |    549.539032 | FunkMonk                                                                                                                                                              |
| 585 |    867.671741 |    366.765370 | Matt Crook                                                                                                                                                            |
| 586 |    894.713603 |    492.934786 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 587 |    967.665279 |    146.312503 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 588 |    440.349704 |    338.348329 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 589 |    698.554315 |    390.588198 | Jaime Headden                                                                                                                                                         |
| 590 |    722.500402 |    610.492048 | Gareth Monger                                                                                                                                                         |
| 591 |    880.234515 |    232.923241 | Andy Wilson                                                                                                                                                           |
| 592 |      9.773257 |    562.395776 | T. Michael Keesey                                                                                                                                                     |
| 593 |    605.078223 |    741.903695 | Chris huh                                                                                                                                                             |
| 594 |    787.784769 |    351.462433 | Zimices                                                                                                                                                               |
| 595 |    605.562542 |    200.779988 | Steven Traver                                                                                                                                                         |
| 596 |    515.699236 |    134.648915 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 597 |    945.115841 |    143.049175 | NA                                                                                                                                                                    |
| 598 |    809.273061 |    415.810113 | T. Michael Keesey                                                                                                                                                     |
| 599 |    236.068201 |    707.158697 | NA                                                                                                                                                                    |
| 600 |    219.957734 |     94.938492 | Margot Michaud                                                                                                                                                        |
| 601 |    811.571713 |    326.740595 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 602 |      7.848973 |    328.927400 | Beth Reinke                                                                                                                                                           |
| 603 |    984.492871 |    231.779625 | Zimices                                                                                                                                                               |
| 604 |    245.224052 |    533.917227 | Matt Crook                                                                                                                                                            |
| 605 |    659.888091 |    620.884250 | Steven Traver                                                                                                                                                         |
| 606 |    538.491397 |    533.101216 | Maija Karala                                                                                                                                                          |
| 607 |    596.677448 |    251.728640 | Konsta Happonen                                                                                                                                                       |
| 608 |    737.382893 |    172.515555 | T. Michael Keesey                                                                                                                                                     |
| 609 |    163.900582 |    358.232590 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 610 |    530.152314 |    663.790451 | Julien Louys                                                                                                                                                          |
| 611 |    449.003101 |    204.794120 | Mathieu Basille                                                                                                                                                       |
| 612 |    685.265660 |    531.135270 | Walter Vladimir                                                                                                                                                       |
| 613 |    773.913497 |    574.297305 | FunkMonk                                                                                                                                                              |
| 614 |    531.816662 |    140.191173 | Scott Hartman                                                                                                                                                         |
| 615 |    497.750126 |    203.847897 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 616 |    825.686831 |    512.683900 | Steven Traver                                                                                                                                                         |
| 617 |    173.171987 |    660.122648 | Manabu Sakamoto                                                                                                                                                       |
| 618 |    740.032988 |    793.137974 | NA                                                                                                                                                                    |
| 619 |    311.096389 |    115.100349 | Collin Gross                                                                                                                                                          |
| 620 |    468.037144 |    772.114554 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 621 |    763.730788 |    389.567019 | T. Michael Keesey                                                                                                                                                     |
| 622 |     19.892716 |    318.853239 | NA                                                                                                                                                                    |
| 623 |    550.614896 |     54.855173 | Michele M Tobias                                                                                                                                                      |
| 624 |    734.549987 |    145.814297 | Inessa Voet                                                                                                                                                           |
| 625 |    942.008412 |     20.632480 | T. Michael Keesey                                                                                                                                                     |
| 626 |    547.712277 |    587.271007 | Matt Crook                                                                                                                                                            |
| 627 |    386.247188 |    547.690557 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 628 |    207.354729 |     90.738613 | Michael Scroggie                                                                                                                                                      |
| 629 |     73.270335 |    340.748429 | Matt Crook                                                                                                                                                            |
| 630 |    851.314515 |    424.121366 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                           |
| 631 |   1013.021633 |    526.891525 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 632 |    833.301665 |    293.257488 | Mario Quevedo                                                                                                                                                         |
| 633 |    486.672335 |    105.498829 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 634 |    694.395232 |    792.144435 | Jagged Fang Designs                                                                                                                                                   |
| 635 |    316.332734 |    555.559301 | Qiang Ou                                                                                                                                                              |
| 636 |     51.727530 |     39.412227 | Chloé Schmidt                                                                                                                                                         |
| 637 |    466.877825 |    656.636458 | Steven Traver                                                                                                                                                         |
| 638 |    459.028772 |    698.369390 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 639 |    641.791856 |     55.734748 | Zimices                                                                                                                                                               |
| 640 |    283.267497 |    603.047671 | Dann Pigdon                                                                                                                                                           |
| 641 |      9.737741 |    629.714835 | Margot Michaud                                                                                                                                                        |
| 642 |    755.872896 |    345.282516 | Steven Traver                                                                                                                                                         |
| 643 |     90.505776 |     51.590144 | Auckland Museum                                                                                                                                                       |
| 644 |    925.745792 |    171.476802 | Aline M. Ghilardi                                                                                                                                                     |
| 645 |    639.519160 |    787.630411 | Ignacio Contreras                                                                                                                                                     |
| 646 |    564.693967 |    651.961066 | Mette Aumala                                                                                                                                                          |
| 647 |    358.870686 |    747.554839 | Steven Traver                                                                                                                                                         |
| 648 |     37.596768 |    254.801631 | Birgit Lang                                                                                                                                                           |
| 649 |    939.840941 |    322.547907 | Sarah Werning                                                                                                                                                         |
| 650 |    545.485707 |     66.801121 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 651 |    389.517464 |    569.817047 | Zimices                                                                                                                                                               |
| 652 |    667.455410 |    241.499328 | Markus A. Grohme                                                                                                                                                      |
| 653 |    926.670332 |    314.294493 | Zimices                                                                                                                                                               |
| 654 |    432.705290 |    621.161942 | Daniel Stadtmauer                                                                                                                                                     |
| 655 |    585.917831 |    152.540993 | Iain Reid                                                                                                                                                             |
| 656 |    716.194196 |    118.234293 | Kamil S. Jaron                                                                                                                                                        |
| 657 |    110.580873 |    296.884191 | Iain Reid                                                                                                                                                             |
| 658 |    294.776673 |    488.095221 | Tyler Greenfield                                                                                                                                                      |
| 659 |    211.108023 |    301.392640 | NA                                                                                                                                                                    |
| 660 |    321.136638 |    670.067810 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 661 |    786.253864 |    272.216911 | Ferran Sayol                                                                                                                                                          |
| 662 |    230.066265 |    152.081135 | Zimices                                                                                                                                                               |
| 663 |    591.754885 |    596.911395 | Gareth Monger                                                                                                                                                         |
| 664 |    879.363353 |    344.719413 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 665 |    223.878744 |    173.526164 | Emily Willoughby                                                                                                                                                      |
| 666 |    646.267508 |    529.384124 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 667 |    768.693201 |    795.715014 | Steven Traver                                                                                                                                                         |
| 668 |    316.063129 |    362.567941 | Chris huh                                                                                                                                                             |
| 669 |    114.619287 |    141.936575 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 670 |    128.839147 |     91.737128 | Duane Raver/USFWS                                                                                                                                                     |
| 671 |    141.630383 |    405.689108 | Margot Michaud                                                                                                                                                        |
| 672 |     38.806660 |    235.217666 | Steven Coombs                                                                                                                                                         |
| 673 |    281.441946 |    394.074675 | Ramona J Heim                                                                                                                                                         |
| 674 |    431.108256 |    613.401589 | Chris huh                                                                                                                                                             |
| 675 |    561.363303 |    287.987781 | Scott Hartman                                                                                                                                                         |
| 676 |    896.612445 |    633.688925 | Emily Willoughby                                                                                                                                                      |
| 677 |    349.919050 |    170.069540 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 678 |    337.973593 |    177.385724 | Scott Hartman                                                                                                                                                         |
| 679 |   1013.705466 |    184.019586 | Jagged Fang Designs                                                                                                                                                   |
| 680 |    642.520530 |    154.723247 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 681 |    449.147103 |    456.283002 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 682 |    982.526784 |    241.376336 | Markus A. Grohme                                                                                                                                                      |
| 683 |     13.401103 |    189.174041 | Margot Michaud                                                                                                                                                        |
| 684 |    289.715356 |    353.619505 | Tauana J. Cunha                                                                                                                                                       |
| 685 |    253.081845 |    627.588190 | Steven Traver                                                                                                                                                         |
| 686 |    271.798477 |    762.716707 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 687 |    644.990301 |    510.105161 | Smokeybjb                                                                                                                                                             |
| 688 |    428.609296 |    215.740183 | Riccardo Percudani                                                                                                                                                    |
| 689 |    690.832798 |    203.169604 | Michelle Site                                                                                                                                                         |
| 690 |    958.182776 |     12.613342 | Gareth Monger                                                                                                                                                         |
| 691 |    714.997098 |    595.243716 | Jagged Fang Designs                                                                                                                                                   |
| 692 |    979.673788 |     81.074309 | NA                                                                                                                                                                    |
| 693 |    676.080773 |    249.530780 | Tasman Dixon                                                                                                                                                          |
| 694 |    833.370696 |    640.748874 | Steven Traver                                                                                                                                                         |
| 695 |    329.319513 |    491.440258 | NA                                                                                                                                                                    |
| 696 |    917.957431 |    147.614608 | Jonathan Wells                                                                                                                                                        |
| 697 |    652.565162 |    535.338412 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 698 |    456.167657 |    778.644240 | NA                                                                                                                                                                    |
| 699 |    678.728826 |    361.899017 | NA                                                                                                                                                                    |
| 700 |    190.310600 |    710.285317 | Zimices                                                                                                                                                               |
| 701 |    473.263757 |    481.150887 | Matt Crook                                                                                                                                                            |
| 702 |    984.701821 |    316.477330 | Manabu Sakamoto                                                                                                                                                       |
| 703 |    888.545735 |    736.181102 | Zimices                                                                                                                                                               |
| 704 |   1019.913322 |    152.579928 | Margot Michaud                                                                                                                                                        |
| 705 |    105.283766 |    787.663150 | Scott Hartman                                                                                                                                                         |
| 706 |    112.274341 |    307.787363 | Andy Wilson                                                                                                                                                           |
| 707 |    457.185915 |    501.609643 | Jake Warner                                                                                                                                                           |
| 708 |    147.405690 |    438.238045 | Gareth Monger                                                                                                                                                         |
| 709 |     75.011665 |    581.671944 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 710 |    639.903162 |    750.506425 | Margot Michaud                                                                                                                                                        |
| 711 |    829.587973 |    787.381476 | NA                                                                                                                                                                    |
| 712 |    258.770600 |    750.168659 | Zimices                                                                                                                                                               |
| 713 |    415.195943 |    482.291690 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 714 |    858.534015 |    594.329838 | Harold N Eyster                                                                                                                                                       |
| 715 |    917.731969 |    280.323892 | Sharon Wegner-Larsen                                                                                                                                                  |
| 716 |    950.507044 |     89.707661 | Caleb M. Brown                                                                                                                                                        |
| 717 |    860.372904 |    155.979032 | Chris huh                                                                                                                                                             |
| 718 |    619.980123 |    637.823540 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 719 |    860.462417 |    257.940390 | T. Michael Keesey                                                                                                                                                     |
| 720 |   1008.957006 |    779.108143 | Jack Mayer Wood                                                                                                                                                       |
| 721 |    131.115419 |    682.599102 | Dean Schnabel                                                                                                                                                         |
| 722 |    945.672660 |     37.024749 | C. Camilo Julián-Caballero                                                                                                                                            |
| 723 |   1000.187072 |    560.955766 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 724 |    751.621812 |    144.567854 | Steven Traver                                                                                                                                                         |
| 725 |    190.166553 |    655.900723 | Margot Michaud                                                                                                                                                        |
| 726 |    158.755406 |     91.661581 | Matt Crook                                                                                                                                                            |
| 727 |    727.150466 |     73.894598 | Jennifer Trimble                                                                                                                                                      |
| 728 |    857.512680 |    759.835806 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 729 |    519.963659 |    448.299370 | T. K. Robinson                                                                                                                                                        |
| 730 |    584.378994 |    405.243068 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 731 |     20.858425 |    465.246906 | Jaime Headden                                                                                                                                                         |
| 732 |     28.049260 |    774.926683 | Sarah Werning                                                                                                                                                         |
| 733 |    411.281239 |    793.441581 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 734 |    155.480977 |     68.187655 | Michele M Tobias                                                                                                                                                      |
| 735 |     55.942857 |    227.439139 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 736 |    919.049729 |    684.895054 | Kimberly Haddrell                                                                                                                                                     |
| 737 |    589.342690 |    192.721198 | Scott Hartman                                                                                                                                                         |
| 738 |    831.395886 |     22.412039 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 739 |    143.104713 |    420.557027 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 740 |    303.181212 |    213.185148 | Andy Wilson                                                                                                                                                           |
| 741 |     90.176500 |    201.386097 | Margot Michaud                                                                                                                                                        |
| 742 |    391.758830 |    457.416202 | Collin Gross                                                                                                                                                          |
| 743 |    473.774379 |    445.144979 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 744 |    123.951510 |    516.351924 | Zimices                                                                                                                                                               |
| 745 |    931.090446 |    718.593448 | Mo Hassan                                                                                                                                                             |
| 746 |    501.654596 |    245.568517 | NA                                                                                                                                                                    |
| 747 |    997.750574 |    470.988757 | FunkMonk                                                                                                                                                              |
| 748 |    432.050474 |    288.296005 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 749 |     18.360256 |    143.960196 | Christoph Schomburg                                                                                                                                                   |
| 750 |    840.180873 |    218.510423 | Scott Hartman                                                                                                                                                         |
| 751 |    718.403447 |    736.376657 | Sean McCann                                                                                                                                                           |
| 752 |    221.429063 |    712.219583 | Sarah Werning                                                                                                                                                         |
| 753 |    199.672808 |     24.159563 | NA                                                                                                                                                                    |
| 754 |    451.940982 |    436.795174 | Elisabeth Östman                                                                                                                                                      |
| 755 |    949.275695 |    491.089859 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 756 |    855.973744 |    338.034351 | Kamil S. Jaron                                                                                                                                                        |
| 757 |    265.175666 |    422.643637 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 758 |    130.226623 |    444.707244 | Markus A. Grohme                                                                                                                                                      |
| 759 |    403.415783 |    376.375485 | Maija Karala                                                                                                                                                          |
| 760 |    563.423166 |     45.982332 | Katie S. Collins                                                                                                                                                      |
| 761 |    184.756170 |     17.256340 | Steven Traver                                                                                                                                                         |
| 762 |    298.789648 |    568.579053 | Baheerathan Murugavel                                                                                                                                                 |
| 763 |    361.951023 |    757.748908 | Sarah Werning                                                                                                                                                         |
| 764 |    752.170275 |    379.945645 | Anna Willoughby                                                                                                                                                       |
| 765 |    963.206412 |     29.258952 | Margot Michaud                                                                                                                                                        |
| 766 |    658.251460 |    334.273559 | Jessica Anne Miller                                                                                                                                                   |
| 767 |    276.625146 |     77.990769 | Brockhaus and Efron                                                                                                                                                   |
| 768 |    515.743184 |    538.546999 | Matt Martyniuk                                                                                                                                                        |
| 769 |    105.247911 |    653.593307 | Matt Crook                                                                                                                                                            |
| 770 |    687.639289 |     83.416559 | Mike Hanson                                                                                                                                                           |
| 771 |    250.000733 |    763.357340 | Melissa Broussard                                                                                                                                                     |
| 772 |    506.766340 |    220.372891 | Ricardo Araújo                                                                                                                                                        |
| 773 |     57.035510 |    778.900638 | Matt Crook                                                                                                                                                            |
| 774 |    943.035961 |    303.251382 | Scott Hartman                                                                                                                                                         |
| 775 |    726.023341 |    101.490926 | CNZdenek                                                                                                                                                              |
| 776 |    313.946976 |     65.237382 | Renato de Carvalho Ferreira                                                                                                                                           |
| 777 |    282.695993 |    714.056839 | Matt Crook                                                                                                                                                            |
| 778 |    734.607131 |    788.563416 | T. Michael Keesey                                                                                                                                                     |
| 779 |    397.018132 |    688.759161 | Steven Traver                                                                                                                                                         |
| 780 |   1011.142649 |    203.825324 | Yan Wong                                                                                                                                                              |
| 781 |    378.193265 |    143.674154 | Steven Traver                                                                                                                                                         |
| 782 |   1008.686053 |     17.820585 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 783 |    999.056921 |    754.668497 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 784 |    398.769011 |    716.052680 | Jagged Fang Designs                                                                                                                                                   |
| 785 |    299.617392 |    552.983148 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 786 |    123.043179 |     54.112379 | Jagged Fang Designs                                                                                                                                                   |
| 787 |     79.700628 |    653.708933 | Chris huh                                                                                                                                                             |
| 788 |    777.584033 |    452.388040 | Jagged Fang Designs                                                                                                                                                   |
| 789 |    490.295402 |    337.204352 | FunkMonk                                                                                                                                                              |
| 790 |   1005.523532 |    218.647032 | Zimices                                                                                                                                                               |
| 791 |    597.274130 |    503.288511 | Margot Michaud                                                                                                                                                        |
| 792 |    978.080453 |    547.421483 | Ignacio Contreras                                                                                                                                                     |
| 793 |    602.640462 |    425.615370 | Sharon Wegner-Larsen                                                                                                                                                  |
| 794 |    826.928779 |    678.859073 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 795 |    401.258907 |    589.272576 | Scott Hartman                                                                                                                                                         |
| 796 |    920.365855 |    377.289935 | Scott Reid                                                                                                                                                            |
| 797 |    225.676997 |    511.205960 | Michelle Site                                                                                                                                                         |
| 798 |    491.611166 |    135.279525 | Kanchi Nanjo                                                                                                                                                          |
| 799 |    172.740623 |    396.448632 | NA                                                                                                                                                                    |
| 800 |    174.887665 |    778.138630 | Steven Traver                                                                                                                                                         |
| 801 |     33.687750 |    460.142562 | Birgit Lang                                                                                                                                                           |
| 802 |    716.886255 |     20.986561 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 803 |     37.835643 |    722.422468 | Kamil S. Jaron                                                                                                                                                        |
| 804 |    344.182357 |    335.293398 | Gareth Monger                                                                                                                                                         |
| 805 |    237.021882 |    681.594333 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 806 |    706.222274 |    161.793975 | Zimices                                                                                                                                                               |
| 807 |    339.894899 |     20.352370 | Matt Crook                                                                                                                                                            |
| 808 |    225.440727 |      8.774389 | Jaime Headden                                                                                                                                                         |
| 809 |    237.914700 |    115.034868 | Margot Michaud                                                                                                                                                        |
| 810 |    990.283849 |    326.036313 | \[unknown\]                                                                                                                                                           |
| 811 |    103.275977 |    128.956384 | Michael Scroggie                                                                                                                                                      |
| 812 |    778.418949 |    764.259745 | C. Camilo Julián-Caballero                                                                                                                                            |
| 813 |    906.121192 |    727.261511 | Jagged Fang Designs                                                                                                                                                   |
| 814 |     80.989061 |    773.097709 | NA                                                                                                                                                                    |
| 815 |    471.980885 |    627.258544 | Jagged Fang Designs                                                                                                                                                   |
| 816 |    670.614700 |    605.916823 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 817 |    690.448508 |    158.644257 | NA                                                                                                                                                                    |
| 818 |    859.391754 |    355.985413 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 819 |    464.135085 |    435.098026 | Tasman Dixon                                                                                                                                                          |
| 820 |    152.768185 |    349.797217 | Ferran Sayol                                                                                                                                                          |
| 821 |     89.479047 |     61.389634 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 822 |    598.248362 |    147.839050 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 823 |    230.505651 |    103.702169 | Kamil S. Jaron                                                                                                                                                        |
| 824 |    548.193976 |    520.637668 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 825 |    701.690808 |    427.992364 | Meliponicultor Itaymbere                                                                                                                                              |
| 826 |    847.303643 |    295.146727 | Zimices                                                                                                                                                               |
| 827 |    847.508151 |    187.846167 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 828 |    671.559152 |    144.880421 | Zimices                                                                                                                                                               |
| 829 |   1013.357986 |    333.545924 | Gareth Monger                                                                                                                                                         |
| 830 |    245.743371 |     67.111540 | Zimices                                                                                                                                                               |
| 831 |    642.900118 |    250.894622 | Andrew A. Farke                                                                                                                                                       |
| 832 |    223.178496 |    181.761551 | Steven Coombs                                                                                                                                                         |
| 833 |    187.507497 |    490.627637 | Matt Crook                                                                                                                                                            |
| 834 |    376.992794 |    697.913483 | Matt Crook                                                                                                                                                            |
| 835 |    758.365895 |    781.272277 | Chris huh                                                                                                                                                             |
| 836 |     28.084567 |    587.862357 | T. Michael Keesey                                                                                                                                                     |
| 837 |    898.825105 |    119.693109 | Gareth Monger                                                                                                                                                         |
| 838 |    428.446051 |    763.764806 | NA                                                                                                                                                                    |
| 839 |    907.627459 |    338.645820 | Ludwik Gąsiorowski                                                                                                                                                    |
| 840 |    544.662873 |    288.886563 | NA                                                                                                                                                                    |
| 841 |    783.866635 |    319.409794 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 842 |    448.698907 |    487.754498 | Christoph Schomburg                                                                                                                                                   |
| 843 |    859.196421 |    608.436266 | Carlos Cano-Barbacil                                                                                                                                                  |
| 844 |    845.922218 |    772.692994 | Gareth Monger                                                                                                                                                         |
| 845 |    889.163839 |    621.181578 | Zimices                                                                                                                                                               |
| 846 |    502.588617 |    181.079684 | Steven Traver                                                                                                                                                         |
| 847 |    986.535888 |    728.614971 | T. Michael Keesey                                                                                                                                                     |
| 848 |     89.905680 |    641.507908 | Yan Wong                                                                                                                                                              |
| 849 |     81.414199 |    432.805591 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 850 |    722.902250 |    656.482786 | Matt Crook                                                                                                                                                            |
| 851 |    873.017461 |    787.280143 | Steven Traver                                                                                                                                                         |
| 852 |    665.035246 |     55.916328 | Felix Vaux                                                                                                                                                            |
| 853 |    486.893458 |    556.041154 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 854 |    821.649643 |    696.370088 | Mathilde Cordellier                                                                                                                                                   |
| 855 |    852.751535 |     40.705515 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 856 |    804.323497 |    517.702016 | Jagged Fang Designs                                                                                                                                                   |
| 857 |    588.553021 |    489.079175 | Andy Wilson                                                                                                                                                           |
| 858 |    286.410106 |    239.318883 | Yan Wong                                                                                                                                                              |
| 859 |    242.613968 |    648.657731 | Margot Michaud                                                                                                                                                        |
| 860 |     42.279014 |    779.634898 | Iain Reid                                                                                                                                                             |
| 861 |    145.033606 |    790.505621 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 862 |    261.496673 |    483.284315 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 863 |    764.416800 |    443.778928 | Matt Crook                                                                                                                                                            |
| 864 |    381.970880 |    130.520416 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 865 |     80.822007 |    662.002594 | Ferran Sayol                                                                                                                                                          |
| 866 |    131.351889 |    372.715838 | Felix Vaux                                                                                                                                                            |
| 867 |    436.318896 |    708.432762 | Zimices                                                                                                                                                               |
| 868 |     36.468892 |    312.303317 | Alex Slavenko                                                                                                                                                         |
| 869 |    651.467139 |    169.313251 | Zimices                                                                                                                                                               |
| 870 |    563.169539 |    508.764280 | Anthony Caravaggi                                                                                                                                                     |
| 871 |    984.146993 |    636.072425 | Scott Hartman                                                                                                                                                         |
| 872 |     11.003292 |    306.504420 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 873 |    128.047267 |     65.499804 | 于川云                                                                                                                                                                   |
| 874 |    624.821402 |     56.188702 | Scott Hartman                                                                                                                                                         |
| 875 |    421.180020 |    708.438746 | Birgit Lang                                                                                                                                                           |
| 876 |     64.342514 |    117.288196 | Jagged Fang Designs                                                                                                                                                   |
| 877 |    614.197851 |    483.352852 | NA                                                                                                                                                                    |
| 878 |     38.377295 |     61.776215 | T. Michael Keesey                                                                                                                                                     |
| 879 |    466.729767 |    540.730508 | Steven Traver                                                                                                                                                         |
| 880 |    583.367021 |    646.832684 | Dean Schnabel                                                                                                                                                         |
| 881 |    369.667301 |    402.719871 | Kamil S. Jaron                                                                                                                                                        |
| 882 |   1004.408679 |    192.055376 | T. Michael Keesey                                                                                                                                                     |
| 883 |    657.472242 |    252.709879 | Gareth Monger                                                                                                                                                         |
| 884 |    461.289256 |    130.158764 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 885 |    998.927294 |    731.045741 | Melissa Broussard                                                                                                                                                     |
| 886 |    187.760294 |     86.367127 | Meliponicultor Itaymbere                                                                                                                                              |
| 887 |    594.912748 |    679.111527 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 888 |    612.137033 |     69.009981 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 889 |    516.790056 |    689.441171 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 890 |    227.918412 |    466.171816 | Margot Michaud                                                                                                                                                        |
| 891 |     16.308488 |    735.211655 | Christoph Schomburg                                                                                                                                                   |
| 892 |    251.670531 |    616.423673 | Robert Gay                                                                                                                                                            |
| 893 |    464.155129 |    111.457602 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 894 |    991.006296 |     26.192464 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 895 |   1015.521561 |    677.641489 | Markus A. Grohme                                                                                                                                                      |
| 896 |    190.970068 |    237.304689 | Andy Wilson                                                                                                                                                           |
| 897 |     99.926730 |    602.119846 | Joedison Rocha                                                                                                                                                        |
| 898 |    580.566188 |     54.769337 | Matt Dempsey                                                                                                                                                          |
| 899 |    380.804818 |    218.278846 | Renata F. Martins                                                                                                                                                     |
| 900 |      9.271729 |    427.308750 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 901 |    118.779133 |    681.789822 | Michelle Site                                                                                                                                                         |
| 902 |    622.254076 |    167.846362 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 903 |    854.366642 |    448.156694 | Gareth Monger                                                                                                                                                         |
| 904 |    430.003892 |      4.538717 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 905 |    446.941304 |    555.618484 | Renato de Carvalho Ferreira                                                                                                                                           |
| 906 |     12.023886 |    373.707551 | Birgit Lang                                                                                                                                                           |
| 907 |    760.565055 |     98.944607 | Qiang Ou                                                                                                                                                              |
| 908 |    757.250980 |    398.421891 | Cesar Julian                                                                                                                                                          |
| 909 |    743.787470 |    526.710388 | Iain Reid                                                                                                                                                             |
| 910 |    791.528487 |    792.606933 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 911 |    942.823851 |    458.898204 | DW Bapst (modified from Mitchell 1990)                                                                                                                                |
| 912 |     13.494369 |    536.642648 | Margot Michaud                                                                                                                                                        |
| 913 |    716.522668 |    400.709117 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 914 |    726.963387 |    442.478225 | Melissa Broussard                                                                                                                                                     |
| 915 |    920.803993 |    656.662362 | Chase Brownstein                                                                                                                                                      |
| 916 |    942.122833 |    395.662998 | Ferran Sayol                                                                                                                                                          |
| 917 |    555.709184 |    474.926115 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                       |
| 918 |    567.275205 |    585.481354 | Birgit Lang                                                                                                                                                           |
| 919 |   1013.216533 |    247.620696 | Gareth Monger                                                                                                                                                         |
| 920 |    319.119532 |      3.726592 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |

    #> Your tweet has been posted!
