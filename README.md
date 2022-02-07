
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

Margot Michaud, Anthony Caravaggi, Jagged Fang Designs, Matthew E.
Clapham, Gabriela Palomo-Munoz, Zimices, David Orr, Ferran Sayol, Matt
Celeskey, Gareth Monger, Matt Crook, Alexander Schmidt-Lebuhn, Tommaso
Cancellario, Ville Koistinen and T. Michael Keesey, Tauana J. Cunha, T.
Michael Keesey, Steven Traver, B. Duygu Özpolat, Allison Pease, Michael
Scroggie, Iain Reid, Christoph Schomburg, T. Michael Keesey
(vectorization); Yves Bousquet (photography), Heinrich Harder
(vectorized by T. Michael Keesey), Scott Hartman, Mason McNair, Ignacio
Contreras, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf
Jondelius (vectorized by T. Michael Keesey), S.Martini, Smokeybjb, John
Gould (vectorized by T. Michael Keesey), Timothy Knepp (vectorized by T.
Michael Keesey), Lily Hughes, Marcos Pérez-Losada, Jens T. Høeg & Keith
A. Crandall, Emily Willoughby, FunkMonk, Dmitry Bogdanov, Obsidian Soul
(vectorized by T. Michael Keesey), Lukas Panzarin, Joanna Wolfe, C.
Camilo Julián-Caballero, Beth Reinke, Markus A. Grohme, T. Michael
Keesey (vector) and Stuart Halliday (photograph), Rebecca Groom, Rene
Martin, Konsta Happonen, CNZdenek, Noah Schlottman, photo from National
Science Foundation - Turbellarian Taxonomic Database, Tony Ayling,
Birgit Lang, Chris huh, L. Shyamal, Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Dean Schnabel, Yan Wong from illustration by Jules Richard (1907),
Auckland Museum and T. Michael Keesey, Michelle Site, Kai R. Caspar,
Armin Reindl, Jaime Headden, Mali’o Kodis, image from Higgins and
Kristensen, 1986, Benjamin Monod-Broca, Meliponicultor Itaymbere, Brad
McFeeters (vectorized by T. Michael Keesey), Maxwell Lefroy (vectorized
by T. Michael Keesey), Maija Karala, Nobu Tamura (vectorized by T.
Michael Keesey), Tasman Dixon, Collin Gross, Campbell Fleming, Yan Wong,
Becky Barnes, Siobhon Egan, Shyamal, Noah Schlottman, Eyal Bartov, Nina
Skinner, Andrew A. Farke, Sarah Werning, Alex Slavenko, Stanton F. Fink
(vectorized by T. Michael Keesey), Manabu Bessho-Uehara, Matt Martyniuk
(vectorized by T. Michael Keesey), xgirouxb, kotik, Julia B McHugh, Lisa
Byrne, Jean-Raphaël Guillaumin (photography) and T. Michael Keesey
(vectorization), Carlos Cano-Barbacil, James R. Spotila and Ray
Chatterji, Matt Martyniuk, Noah Schlottman, photo by Reinhard Jahn,
Scott Reid, Nobu Tamura, modified by Andrew A. Farke, Mateus Zica
(modified by T. Michael Keesey), Noah Schlottman, photo by Gustav Paulay
for Moorea Biocode, Kamil S. Jaron, Ryan Cupo, Josep Marti Solans, Jaime
Headden, modified by T. Michael Keesey, Sergio A. Muñoz-Gómez, Sherman
F. Denton via rawpixel.com (illustration) and Timothy J. Bartley
(silhouette), Nobu Tamura, vectorized by Zimices, Noah Schlottman, photo
by Carlos Sánchez-Ortiz, Kent Elson Sorgon, Dmitry Bogdanov (vectorized
by T. Michael Keesey), Neil Kelley, Tracy A. Heath, Jiekun He, Dmitry
Bogdanov (modified by T. Michael Keesey), FJDegrange, Noah Schlottman,
photo by Adam G. Clause, Konsta Happonen, from a CC-BY-NC image by
pelhonen on iNaturalist, Konsta Happonen, from a CC-BY-NC image by
sokolkov2002 on iNaturalist, Kanchi Nanjo, Joseph Wolf, 1863
(vectorization by Dinah Challen), Jake Warner, Robbie N. Cada (modified
by T. Michael Keesey), L.M. Davalos, Tyler McCraney, Oliver Griffith,
Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Matt Wilkins, Chase Brownstein,
Harold N Eyster, Giant Blue Anteater (vectorized by T. Michael Keesey),
Mike Hanson, Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), Sam Droege (photography) and T. Michael Keesey (vectorization),
Lukasiniho, Steven Coombs, Lafage, Hans Hillewaert (vectorized by T.
Michael Keesey), Maxime Dahirel, T. Michael Keesey (vectorization) and
Nadiatalent (photography), Arthur Weasley (vectorized by T. Michael
Keesey), Dexter R. Mardis, Sharon Wegner-Larsen, Verisimilus, Nobu
Tamura (modified by T. Michael Keesey), Jose Carlos Arenas-Monroy,
Josefine Bohr Brask, Sam Fraser-Smith (vectorized by T. Michael Keesey),
T. Michael Keesey (after Walker & al.), Chuanixn Yu, Christine Axon,
Aline M. Ghilardi, Cesar Julian, George Edward Lodge (vectorized by T.
Michael Keesey), Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong,
Christopher Laumer (vectorized by T. Michael Keesey), Adam Stuart Smith
(vectorized by T. Michael Keesey), Yan Wong from drawing in The Century
Dictionary (1911), DW Bapst, modified from Ishitani et al. 2016, Mattia
Menchetti, Melissa Broussard, Juan Carlos Jerí, Danielle Alba, V.
Deepak, I. Sácek, Sr. (vectorized by T. Michael Keesey), Birgit Lang;
original image by virmisco.org, Caleb M. Brown, Martin R. Smith,
Jonathan Wells, Darren Naish, Nemo, and T. Michael Keesey, Alexandre
Vong, Roberto Díaz Sibaja, Matt Martyniuk (modified by T. Michael
Keesey), Ingo Braasch, Richard J. Harris, Scott Hartman (vectorized by
T. Michael Keesey), Ron Holmes/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), Francis de Laporte de
Castelnau (vectorized by T. Michael Keesey), Duane Raver/USFWS, Emma
Hughes, Mathew Wedel, Henry Lydecker, Taenadoman, Manabu Sakamoto,
Arthur S. Brum, Mali’o Kodis, photograph by Jim Vargo, Dinah Challen,
Archaeodontosaurus (vectorized by T. Michael Keesey), Apokryltaros
(vectorized by T. Michael Keesey), Francisco Manuel Blanco (vectorized
by T. Michael Keesey), Original drawing by Dmitry Bogdanov, vectorized
by Roberto Díaz Sibaja, Sibi (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Casey Dunn, Ellen Edmonson and Hugh Chrisp
(vectorized by T. Michael Keesey), Lisa M. “Pixxl” (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, terngirl, Frank
Förster, RS, Mathieu Basille, Joedison Rocha, Mali’o Kodis, image from
the Biodiversity Heritage Library, Tony Ayling (vectorized by T. Michael
Keesey), Daniel Stadtmauer, Mali’o Kodis, photograph by G. Giribet,
Eduard Solà Vázquez, vectorised by Yan Wong, Amanda Katzer, Pollyanna
von Knorring and T. Michael Keesey, Abraão Leite, Yan Wong from
wikipedia drawing (PD: Pearson Scott Foresman), Johan Lindgren, Michael
W. Caldwell, Takuya Konishi, Luis M. Chiappe, SecretJellyMan, Mathilde
Cordellier, Mattia Menchetti / Yan Wong, Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette), mystica, Chris
A. Hamilton, Noah Schlottman, photo from Casey Dunn, Lee Harding
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Jack Mayer Wood, François Michonneau, Tyler Greenfield, Steven
Haddock • Jellywatch.org, Matt Wilkins (photo by Patrick Kavanagh),
Joseph J. W. Sertich, Mark A. Loewen, Pete Buchholz, Dmitry Bogdanov,
vectorized by Zimices, Michael P. Taylor, Mariana Ruiz Villarreal
(modified by T. Michael Keesey), Katie S. Collins, David Sim
(photograph) and T. Michael Keesey (vectorization), Michael Scroggie,
from original photograph by John Bettaso, USFWS (original photograph in
public domain)., Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Stephen O’Connor
(vectorized by T. Michael Keesey), Ghedoghedo (vectorized by T. Michael
Keesey), SecretJellyMan - from Mason McNair, Scott D. Sampson, Mark A.
Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua
A. Smith, Alan L. Titus, Bruno C. Vellutini, Didier Descouens
(vectorized by T. Michael Keesey), Terpsichores, Kevin Sánchez,
Metalhead64 (vectorized by T. Michael Keesey), T. K. Robinson, Darius
Nau, Mykle Hoban, James I. Kirkland, Luis Alcalá, Mark A. Loewen,
Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T.
Michael Keesey), Milton Tan, Emil Schmidt (vectorized by Maxime
Dahirel), Andrés Sánchez, Kailah Thorn & Mark Hutchinson, Cathy, Karla
Martinez, Rachel Shoop, Chris Jennings (Risiatto), Ville-Veikko
Sinkkonen, Crystal Maier, Peileppe, Stemonitis (photography) and T.
Michael Keesey (vectorization), Oscar Sanisidro, Zsoldos Márton
(vectorized by T. Michael Keesey), Lankester Edwin Ray (vectorized by T.
Michael Keesey), Darren Naish (vectorized by T. Michael Keesey), Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., Owen Jones, Robert Bruce Horsfall, from
W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”,
Lauren Sumner-Rooney, Sarefo (vectorized by T. Michael Keesey), G. M.
Woodward, T. Tischler, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Liftarn, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Felix Vaux, Robert
Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey., M
Kolmann, Félix Landry Yuan, Prin Pattawaro (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Taro Maeda, Zachary
Quigley, T. Michael Keesey (after C. De Muizon), Mali’o Kodis,
photograph by Melissa Frey, Jebulon (vectorized by T. Michael Keesey),
Renata F. Martins, TaraTaylorDesign, Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Mali’o Kodis, photograph
by P. Funch and R.M. Kristensen

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    329.240818 |    431.676344 | Margot Michaud                                                                                                                                                        |
|   2 |    223.469123 |    534.023640 | NA                                                                                                                                                                    |
|   3 |    605.732369 |    653.010433 | Anthony Caravaggi                                                                                                                                                     |
|   4 |    856.137615 |    282.238428 | Jagged Fang Designs                                                                                                                                                   |
|   5 |    184.888929 |    158.033246 | Matthew E. Clapham                                                                                                                                                    |
|   6 |    537.913952 |    139.698442 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   7 |    503.549879 |    316.424994 | Zimices                                                                                                                                                               |
|   8 |    736.806279 |    555.757206 | David Orr                                                                                                                                                             |
|   9 |    851.100701 |    150.245378 | Ferran Sayol                                                                                                                                                          |
|  10 |    933.835863 |    580.333217 | Matt Celeskey                                                                                                                                                         |
|  11 |    919.061106 |     34.905514 | Zimices                                                                                                                                                               |
|  12 |    693.323171 |    105.489497 | Gareth Monger                                                                                                                                                         |
|  13 |    358.601915 |    580.845690 | Matt Crook                                                                                                                                                            |
|  14 |    343.962328 |    320.062372 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  15 |    720.818723 |    271.242389 | Tommaso Cancellario                                                                                                                                                   |
|  16 |    241.850061 |    669.010520 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
|  17 |    737.338693 |    446.204433 | Ferran Sayol                                                                                                                                                          |
|  18 |     90.609316 |    736.786311 | Margot Michaud                                                                                                                                                        |
|  19 |     78.505383 |    527.740196 | Tauana J. Cunha                                                                                                                                                       |
|  20 |    927.295747 |    367.524440 | T. Michael Keesey                                                                                                                                                     |
|  21 |    597.185340 |    342.509255 | Steven Traver                                                                                                                                                         |
|  22 |    386.363835 |    699.041891 | B. Duygu Özpolat                                                                                                                                                      |
|  23 |    558.926547 |    450.762331 | Margot Michaud                                                                                                                                                        |
|  24 |    828.025695 |    687.861564 | Allison Pease                                                                                                                                                         |
|  25 |    205.911225 |    357.068895 | Margot Michaud                                                                                                                                                        |
|  26 |    868.534108 |    494.929557 | Michael Scroggie                                                                                                                                                      |
|  27 |    787.414853 |    359.617635 | Iain Reid                                                                                                                                                             |
|  28 |    954.681675 |    720.005329 | Christoph Schomburg                                                                                                                                                   |
|  29 |    435.761542 |     68.631791 | Zimices                                                                                                                                                               |
|  30 |     42.180629 |     61.560238 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
|  31 |    835.222805 |    751.033440 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
|  32 |    270.746243 |    261.178430 | Jagged Fang Designs                                                                                                                                                   |
|  33 |    569.415331 |    767.811754 | Gareth Monger                                                                                                                                                         |
|  34 |    493.263631 |    620.509202 | Scott Hartman                                                                                                                                                         |
|  35 |    672.515614 |    739.396390 | Mason McNair                                                                                                                                                          |
|  36 |    544.505954 |    522.714494 | Gareth Monger                                                                                                                                                         |
|  37 |    773.938519 |    258.620141 | Gareth Monger                                                                                                                                                         |
|  38 |    400.435644 |    480.846803 | Ignacio Contreras                                                                                                                                                     |
|  39 |    435.490321 |    189.305002 | NA                                                                                                                                                                    |
|  40 |    165.028642 |     47.968745 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
|  41 |    606.985735 |    561.069339 | Zimices                                                                                                                                                               |
|  42 |    299.548602 |     22.426780 | Jagged Fang Designs                                                                                                                                                   |
|  43 |     96.501766 |    630.436066 | Gareth Monger                                                                                                                                                         |
|  44 |    340.869053 |    138.054914 | S.Martini                                                                                                                                                             |
|  45 |    694.715634 |    388.419121 | Gareth Monger                                                                                                                                                         |
|  46 |    928.671050 |    146.836196 | NA                                                                                                                                                                    |
|  47 |    347.925445 |    247.578923 | Smokeybjb                                                                                                                                                             |
|  48 |    634.385658 |     84.554501 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
|  49 |     70.731668 |    596.754190 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
|  50 |     65.118930 |    279.736300 | NA                                                                                                                                                                    |
|  51 |     43.243460 |    431.619193 | Christoph Schomburg                                                                                                                                                   |
|  52 |    901.748311 |    218.778453 | Lily Hughes                                                                                                                                                           |
|  53 |    204.634765 |    466.852657 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                 |
|  54 |    176.110262 |    300.331253 | Emily Willoughby                                                                                                                                                      |
|  55 |    537.658582 |    394.325749 | FunkMonk                                                                                                                                                              |
|  56 |    960.172120 |    250.918462 | Ferran Sayol                                                                                                                                                          |
|  57 |    300.006382 |    761.011235 | Dmitry Bogdanov                                                                                                                                                       |
|  58 |    482.381366 |    263.056456 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  59 |    386.141524 |    409.648056 | Lukas Panzarin                                                                                                                                                        |
|  60 |    488.323201 |    567.701605 | Joanna Wolfe                                                                                                                                                          |
|  61 |    653.023034 |    221.780820 | C. Camilo Julián-Caballero                                                                                                                                            |
|  62 |    737.514007 |    123.127943 | Beth Reinke                                                                                                                                                           |
|  63 |    465.626837 |    784.324504 | Markus A. Grohme                                                                                                                                                      |
|  64 |    988.090841 |    428.256257 | NA                                                                                                                                                                    |
|  65 |    731.484866 |    608.569479 | NA                                                                                                                                                                    |
|  66 |    949.493015 |     85.881883 | Zimices                                                                                                                                                               |
|  67 |    857.013959 |    625.918577 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
|  68 |    334.764667 |     73.482159 | Ignacio Contreras                                                                                                                                                     |
|  69 |    954.873123 |    522.381411 | Ferran Sayol                                                                                                                                                          |
|  70 |    578.898932 |    100.959472 | Steven Traver                                                                                                                                                         |
|  71 |    633.101827 |    488.514705 | Rebecca Groom                                                                                                                                                         |
|  72 |    104.244402 |    663.311205 | Rene Martin                                                                                                                                                           |
|  73 |    478.290570 |    669.226265 | Margot Michaud                                                                                                                                                        |
|  74 |    926.303381 |    294.637897 | Beth Reinke                                                                                                                                                           |
|  75 |    128.062129 |    453.606783 | Konsta Happonen                                                                                                                                                       |
|  76 |    822.208573 |    401.702629 | CNZdenek                                                                                                                                                              |
|  77 |    475.965856 |    727.758587 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
|  78 |    885.652027 |    649.408076 | Tony Ayling                                                                                                                                                           |
|  79 |    165.710825 |    710.711518 | Birgit Lang                                                                                                                                                           |
|  80 |    314.819100 |    197.242125 | Matt Crook                                                                                                                                                            |
|  81 |    269.905080 |    246.839042 | NA                                                                                                                                                                    |
|  82 |    377.512379 |      4.251515 | Chris huh                                                                                                                                                             |
|  83 |    381.363331 |    230.799911 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  84 |    720.698018 |    492.536020 | L. Shyamal                                                                                                                                                            |
|  85 |     74.773573 |    344.901814 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  86 |    512.747454 |    213.833340 | Dean Schnabel                                                                                                                                                         |
|  87 |    729.434322 |    756.151833 | Ferran Sayol                                                                                                                                                          |
|  88 |    222.968670 |    770.125090 | NA                                                                                                                                                                    |
|  89 |    234.019522 |    557.828544 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
|  90 |    413.610930 |    371.252976 | Zimices                                                                                                                                                               |
|  91 |    622.427231 |    288.426079 | L. Shyamal                                                                                                                                                            |
|  92 |    255.420944 |     61.264030 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
|  93 |    988.801411 |    495.071727 | Michelle Site                                                                                                                                                         |
|  94 |    560.724396 |    731.290926 | Kai R. Caspar                                                                                                                                                         |
|  95 |    289.599495 |    595.914560 | Matt Crook                                                                                                                                                            |
|  96 |    849.939242 |     10.214546 | Armin Reindl                                                                                                                                                          |
|  97 |    450.375641 |    709.880666 | Jaime Headden                                                                                                                                                         |
|  98 |    704.563984 |    681.859482 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
|  99 |    307.290815 |    143.475009 | Benjamin Monod-Broca                                                                                                                                                  |
| 100 |     65.607955 |    223.272631 | Meliponicultor Itaymbere                                                                                                                                              |
| 101 |    372.039787 |     32.163742 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 102 |    251.893910 |     75.491434 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 103 |    909.817261 |    242.096557 | Maija Karala                                                                                                                                                          |
| 104 |    124.687209 |    272.689246 | Margot Michaud                                                                                                                                                        |
| 105 |     44.696491 |    119.423931 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 106 |    998.555277 |    203.652952 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 107 |    339.528146 |    759.829863 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 108 |    812.768186 |    298.503629 | NA                                                                                                                                                                    |
| 109 |    845.099815 |    330.516327 | Tasman Dixon                                                                                                                                                          |
| 110 |    942.850756 |    443.946893 | Beth Reinke                                                                                                                                                           |
| 111 |    798.738205 |    281.051112 | Margot Michaud                                                                                                                                                        |
| 112 |    307.815991 |    285.685727 | Collin Gross                                                                                                                                                          |
| 113 |    505.268973 |    418.560608 | Gareth Monger                                                                                                                                                         |
| 114 |    183.840043 |    420.229400 | T. Michael Keesey                                                                                                                                                     |
| 115 |    220.660434 |     44.210237 | Campbell Fleming                                                                                                                                                      |
| 116 |   1013.406822 |    633.507347 | Yan Wong                                                                                                                                                              |
| 117 |    300.211457 |    542.053886 | Ferran Sayol                                                                                                                                                          |
| 118 |     72.952841 |    160.934373 | Jagged Fang Designs                                                                                                                                                   |
| 119 |    309.487975 |    461.248469 | Becky Barnes                                                                                                                                                          |
| 120 |    377.222602 |     57.313533 | Siobhon Egan                                                                                                                                                          |
| 121 |     99.404057 |    467.221154 | Gareth Monger                                                                                                                                                         |
| 122 |    984.152970 |    753.993132 | Michael Scroggie                                                                                                                                                      |
| 123 |    251.785390 |    398.717618 | Shyamal                                                                                                                                                               |
| 124 |    444.277347 |    502.981876 | Tasman Dixon                                                                                                                                                          |
| 125 |    813.565453 |    492.053433 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 126 |    538.729655 |    225.774084 | Noah Schlottman                                                                                                                                                       |
| 127 |    837.139054 |    593.683964 | Zimices                                                                                                                                                               |
| 128 |    349.602722 |    207.128608 | Matt Crook                                                                                                                                                            |
| 129 |     92.634387 |    367.713141 | Eyal Bartov                                                                                                                                                           |
| 130 |    763.700032 |    321.030916 | Steven Traver                                                                                                                                                         |
| 131 |    953.300427 |    312.420929 | Tasman Dixon                                                                                                                                                          |
| 132 |    555.323193 |     17.645844 | Markus A. Grohme                                                                                                                                                      |
| 133 |    779.408178 |      3.849755 | Nina Skinner                                                                                                                                                          |
| 134 |    810.224151 |     65.132832 | C. Camilo Julián-Caballero                                                                                                                                            |
| 135 |    451.226532 |    434.958274 | T. Michael Keesey                                                                                                                                                     |
| 136 |    957.725282 |    192.470669 | Chris huh                                                                                                                                                             |
| 137 |    603.227859 |    414.984540 | Dean Schnabel                                                                                                                                                         |
| 138 |    292.860263 |    116.522255 | Rebecca Groom                                                                                                                                                         |
| 139 |    778.665507 |    141.768131 | Jagged Fang Designs                                                                                                                                                   |
| 140 |    955.894804 |    673.059758 | Chris huh                                                                                                                                                             |
| 141 |     27.207721 |    458.202142 | Andrew A. Farke                                                                                                                                                       |
| 142 |    183.585070 |    651.030485 | Ferran Sayol                                                                                                                                                          |
| 143 |     82.621466 |    111.980986 | Iain Reid                                                                                                                                                             |
| 144 |    871.185031 |    786.534212 | Ferran Sayol                                                                                                                                                          |
| 145 |    921.154205 |     99.085065 | Matt Crook                                                                                                                                                            |
| 146 |     13.094534 |    588.089608 | Rebecca Groom                                                                                                                                                         |
| 147 |    271.312996 |     50.090411 | Markus A. Grohme                                                                                                                                                      |
| 148 |    404.145713 |    113.844083 | Zimices                                                                                                                                                               |
| 149 |    172.355278 |    749.466349 | Margot Michaud                                                                                                                                                        |
| 150 |   1005.566676 |    306.806997 | Matt Crook                                                                                                                                                            |
| 151 |    867.438488 |     77.365106 | Sarah Werning                                                                                                                                                         |
| 152 |    759.292928 |    771.022794 | Tauana J. Cunha                                                                                                                                                       |
| 153 |    452.465185 |    670.475603 | Alex Slavenko                                                                                                                                                         |
| 154 |    902.576642 |    776.495727 | Zimices                                                                                                                                                               |
| 155 |    354.283594 |    513.026239 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 156 |    688.846359 |    514.550482 | Manabu Bessho-Uehara                                                                                                                                                  |
| 157 |    428.137150 |    438.256815 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 158 |    374.368624 |    773.744467 | Steven Traver                                                                                                                                                         |
| 159 |    526.228083 |    508.073783 | Zimices                                                                                                                                                               |
| 160 |    747.899311 |    647.336560 | Jagged Fang Designs                                                                                                                                                   |
| 161 |    750.450795 |    129.713062 | NA                                                                                                                                                                    |
| 162 |    730.356393 |    721.526904 | xgirouxb                                                                                                                                                              |
| 163 |    849.515655 |     25.896441 | Beth Reinke                                                                                                                                                           |
| 164 |    994.247762 |    348.180358 | Tasman Dixon                                                                                                                                                          |
| 165 |   1000.550667 |    692.136809 | Collin Gross                                                                                                                                                          |
| 166 |    130.615612 |    693.251936 | T. Michael Keesey                                                                                                                                                     |
| 167 |    664.457361 |    275.003274 | Matt Crook                                                                                                                                                            |
| 168 |    681.218951 |    409.776745 | kotik                                                                                                                                                                 |
| 169 |    566.954503 |    212.918608 | Julia B McHugh                                                                                                                                                        |
| 170 |     92.194490 |     35.659552 | Matt Crook                                                                                                                                                            |
| 171 |    519.757992 |    714.066362 | Lisa Byrne                                                                                                                                                            |
| 172 |    148.487223 |    694.861989 | Yan Wong                                                                                                                                                              |
| 173 |    858.231293 |    268.730915 | Alex Slavenko                                                                                                                                                         |
| 174 |    179.403280 |    259.214638 | Markus A. Grohme                                                                                                                                                      |
| 175 |    245.605780 |    738.206202 | xgirouxb                                                                                                                                                              |
| 176 |    838.799126 |    263.249654 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 177 |    182.318914 |    522.424288 | Margot Michaud                                                                                                                                                        |
| 178 |    709.522125 |    353.952908 | Margot Michaud                                                                                                                                                        |
| 179 |    511.913868 |     25.829264 | NA                                                                                                                                                                    |
| 180 |    858.507093 |    137.065832 | Steven Traver                                                                                                                                                         |
| 181 |     83.422530 |    398.735443 | Carlos Cano-Barbacil                                                                                                                                                  |
| 182 |    294.423610 |    320.122768 | T. Michael Keesey                                                                                                                                                     |
| 183 |    459.671585 |    695.830130 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 184 |    916.853224 |    664.049027 | T. Michael Keesey                                                                                                                                                     |
| 185 |    868.907098 |    665.941204 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 186 |     29.701415 |    217.452925 | Matt Martyniuk                                                                                                                                                        |
| 187 |    488.869474 |    143.316941 | Jaime Headden                                                                                                                                                         |
| 188 |    763.071878 |    632.070357 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 189 |    638.893543 |     24.427379 | Scott Reid                                                                                                                                                            |
| 190 |     96.919848 |    689.140644 | L. Shyamal                                                                                                                                                            |
| 191 |    704.782279 |    336.033345 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 192 |    428.980743 |    688.848522 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 193 |     57.685004 |    487.253195 | Matt Crook                                                                                                                                                            |
| 194 |    940.454357 |    202.767930 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 195 |     73.837225 |     51.321132 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 196 |    394.445397 |    151.766146 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                            |
| 197 |    348.166111 |    785.856382 | Kamil S. Jaron                                                                                                                                                        |
| 198 |    979.200386 |     46.947834 | Ryan Cupo                                                                                                                                                             |
| 199 |    726.137549 |    196.259744 | NA                                                                                                                                                                    |
| 200 |    158.033868 |    721.070258 | Matt Celeskey                                                                                                                                                         |
| 201 |    149.013265 |    549.981612 | Josep Marti Solans                                                                                                                                                    |
| 202 |    613.518881 |    300.554577 | Margot Michaud                                                                                                                                                        |
| 203 |      5.540637 |    106.117986 | Gareth Monger                                                                                                                                                         |
| 204 |    917.848689 |    432.162921 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 205 |    981.377586 |    786.289606 | Zimices                                                                                                                                                               |
| 206 |    297.528382 |    725.091700 | Zimices                                                                                                                                                               |
| 207 |     48.690831 |    207.027669 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 208 |    559.605800 |    105.496581 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 209 |   1008.112846 |    661.215149 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 210 |    363.998673 |    503.013526 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 211 |    959.663904 |    446.042078 | T. Michael Keesey                                                                                                                                                     |
| 212 |    955.222001 |    167.493708 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 213 |    402.958849 |    443.050046 | Lily Hughes                                                                                                                                                           |
| 214 |    152.465152 |    275.691498 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 215 |    485.012750 |     90.624222 | Kent Elson Sorgon                                                                                                                                                     |
| 216 |    645.333406 |    786.796448 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 217 |    720.863314 |    314.690346 | Neil Kelley                                                                                                                                                           |
| 218 |    335.634888 |    372.356561 | Matt Crook                                                                                                                                                            |
| 219 |    611.894370 |     78.421326 | Steven Traver                                                                                                                                                         |
| 220 |     37.065101 |    641.183681 | Tracy A. Heath                                                                                                                                                        |
| 221 |    201.928082 |    728.692879 | Jaime Headden                                                                                                                                                         |
| 222 |    445.606569 |    755.420322 | Matt Crook                                                                                                                                                            |
| 223 |    664.751369 |    569.581091 | Gareth Monger                                                                                                                                                         |
| 224 |    641.767151 |    181.619308 | Jiekun He                                                                                                                                                             |
| 225 |    710.033054 |    633.635241 | Margot Michaud                                                                                                                                                        |
| 226 |    282.043073 |    738.640644 | Alex Slavenko                                                                                                                                                         |
| 227 |    172.046185 |    615.496119 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 228 |    727.921617 |     17.563120 | Gareth Monger                                                                                                                                                         |
| 229 |    376.899871 |    190.579509 | FJDegrange                                                                                                                                                            |
| 230 |    265.276027 |    534.370966 | T. Michael Keesey                                                                                                                                                     |
| 231 |    400.269855 |    268.819842 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 232 |    180.791276 |    625.276263 | Tasman Dixon                                                                                                                                                          |
| 233 |    572.124094 |    624.712336 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 234 |    897.941619 |    333.152070 | Margot Michaud                                                                                                                                                        |
| 235 |    771.161238 |    533.148496 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 236 |    653.959381 |    409.121798 | Matt Crook                                                                                                                                                            |
| 237 |    692.539379 |    357.979641 | L. Shyamal                                                                                                                                                            |
| 238 |    140.715644 |    602.583256 | Zimices                                                                                                                                                               |
| 239 |    789.155082 |    447.265306 | Scott Hartman                                                                                                                                                         |
| 240 |    653.399533 |    433.335368 | Matt Crook                                                                                                                                                            |
| 241 |    630.066839 |    264.394973 | Gareth Monger                                                                                                                                                         |
| 242 |    594.838654 |    130.761108 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
| 243 |     86.413171 |     18.467538 | Ferran Sayol                                                                                                                                                          |
| 244 |    483.139127 |    518.489760 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 245 |    485.284603 |    211.755726 | Kai R. Caspar                                                                                                                                                         |
| 246 |    606.866299 |    487.609712 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 247 |     55.295574 |    609.344182 | NA                                                                                                                                                                    |
| 248 |    169.893887 |    443.765820 | Dean Schnabel                                                                                                                                                         |
| 249 |    619.425109 |    170.044630 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 250 |    183.405451 |    309.413887 | Kanchi Nanjo                                                                                                                                                          |
| 251 |    752.541288 |     39.493051 | Chris huh                                                                                                                                                             |
| 252 |    403.963545 |    418.648962 | Zimices                                                                                                                                                               |
| 253 |    906.736930 |    385.586297 | Carlos Cano-Barbacil                                                                                                                                                  |
| 254 |    715.477007 |    716.949915 | Emily Willoughby                                                                                                                                                      |
| 255 |    318.101048 |    672.469571 | Zimices                                                                                                                                                               |
| 256 |    812.927172 |    502.009980 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 257 |    249.421339 |    597.318050 | Jake Warner                                                                                                                                                           |
| 258 |    506.276846 |    747.441742 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 259 |    583.382121 |    273.422859 | Steven Traver                                                                                                                                                         |
| 260 |    663.422379 |    254.070977 | L.M. Davalos                                                                                                                                                          |
| 261 |    735.348098 |    689.376606 | Joanna Wolfe                                                                                                                                                          |
| 262 |    414.085769 |    256.874389 | Margot Michaud                                                                                                                                                        |
| 263 |      8.784951 |    471.332405 | Ferran Sayol                                                                                                                                                          |
| 264 |    324.187100 |    173.327727 | Margot Michaud                                                                                                                                                        |
| 265 |     63.072711 |    790.151464 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 266 |   1000.270713 |    757.559801 | NA                                                                                                                                                                    |
| 267 |   1002.900780 |    539.505830 | Dean Schnabel                                                                                                                                                         |
| 268 |    516.196386 |    701.889723 | Tyler McCraney                                                                                                                                                        |
| 269 |    222.002794 |    279.283010 | Oliver Griffith                                                                                                                                                       |
| 270 |    540.072486 |    577.063204 | Joanna Wolfe                                                                                                                                                          |
| 271 |    993.001921 |    628.427618 | T. Michael Keesey                                                                                                                                                     |
| 272 |    895.661591 |    375.561507 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 273 |    802.942045 |    542.897272 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 274 |    979.068548 |    224.190593 | Matt Wilkins                                                                                                                                                          |
| 275 |    521.450791 |    497.777763 | Zimices                                                                                                                                                               |
| 276 |    252.142347 |    510.490694 | Chase Brownstein                                                                                                                                                      |
| 277 |    435.600954 |    316.761855 | Harold N Eyster                                                                                                                                                       |
| 278 |    207.424978 |    608.162960 | Tauana J. Cunha                                                                                                                                                       |
| 279 |    215.823106 |    730.456702 | Chris huh                                                                                                                                                             |
| 280 |    336.464709 |    648.078365 | Steven Traver                                                                                                                                                         |
| 281 |   1012.737268 |     62.865904 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 282 |      8.547123 |    672.988495 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 283 |    628.717326 |    393.625069 | Mike Hanson                                                                                                                                                           |
| 284 |    308.473036 |    657.714456 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 285 |    654.667450 |    207.881848 | Jagged Fang Designs                                                                                                                                                   |
| 286 |    452.031488 |     32.267350 | Tracy A. Heath                                                                                                                                                        |
| 287 |     11.520201 |    575.517498 | Matt Crook                                                                                                                                                            |
| 288 |    430.649885 |    455.909030 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 289 |    642.675949 |    511.688481 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 290 |    810.924248 |    597.816756 | Margot Michaud                                                                                                                                                        |
| 291 |    197.344105 |    314.586179 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 292 |    846.878929 |     51.257034 | C. Camilo Julián-Caballero                                                                                                                                            |
| 293 |    406.824626 |    766.138368 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 294 |    322.027000 |    512.625358 | Margot Michaud                                                                                                                                                        |
| 295 |    181.597132 |    750.086097 | FJDegrange                                                                                                                                                            |
| 296 |    489.526045 |    587.270903 | Lukasiniho                                                                                                                                                            |
| 297 |    245.842527 |    246.666749 | FunkMonk                                                                                                                                                              |
| 298 |    328.912767 |    794.941611 | Steven Coombs                                                                                                                                                         |
| 299 |    490.392128 |    430.906516 | Lafage                                                                                                                                                                |
| 300 |    844.272440 |     94.718845 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 301 |    348.851862 |    274.284133 | Maxime Dahirel                                                                                                                                                        |
| 302 |    574.137394 |    302.279282 | Tauana J. Cunha                                                                                                                                                       |
| 303 |    415.732351 |    270.071755 | Chris huh                                                                                                                                                             |
| 304 |    628.371856 |    430.740640 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 305 |    242.722559 |    410.897701 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 306 |    891.219659 |    107.371730 | Anthony Caravaggi                                                                                                                                                     |
| 307 |    222.084862 |    305.477009 | Zimices                                                                                                                                                               |
| 308 |    198.431235 |    792.166392 | Dean Schnabel                                                                                                                                                         |
| 309 |    280.699386 |    277.460774 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 310 |    734.872321 |    515.441776 | Ignacio Contreras                                                                                                                                                     |
| 311 |     63.166628 |    185.453479 | Matt Crook                                                                                                                                                            |
| 312 |    165.406703 |    509.535512 | Noah Schlottman                                                                                                                                                       |
| 313 |    483.367011 |    136.048265 | Dexter R. Mardis                                                                                                                                                      |
| 314 |    221.028191 |    525.538190 | Jake Warner                                                                                                                                                           |
| 315 |    381.519073 |    171.569275 | Matt Crook                                                                                                                                                            |
| 316 |     14.112615 |    188.499990 | Sharon Wegner-Larsen                                                                                                                                                  |
| 317 |    847.073953 |    230.762428 | Chris huh                                                                                                                                                             |
| 318 |    683.108145 |    648.654651 | Verisimilus                                                                                                                                                           |
| 319 |    812.101589 |    667.164061 | Maija Karala                                                                                                                                                          |
| 320 |    392.434783 |    249.741864 | Markus A. Grohme                                                                                                                                                      |
| 321 |    761.741739 |     51.423159 | Neil Kelley                                                                                                                                                           |
| 322 |    768.835964 |     86.189591 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 323 |    480.548374 |    641.782282 | Zimices                                                                                                                                                               |
| 324 |     94.714499 |    426.709619 | Zimices                                                                                                                                                               |
| 325 |    798.213129 |     25.130958 | Margot Michaud                                                                                                                                                        |
| 326 |    363.314845 |     94.471670 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 327 |     45.071270 |    352.278668 | T. Michael Keesey                                                                                                                                                     |
| 328 |    679.567436 |    449.611422 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 329 |    115.302516 |     73.700677 | Noah Schlottman                                                                                                                                                       |
| 330 |    499.930061 |    500.397941 | NA                                                                                                                                                                    |
| 331 |    616.582191 |     10.296387 | Josefine Bohr Brask                                                                                                                                                   |
| 332 |    741.623151 |    167.957173 | Tasman Dixon                                                                                                                                                          |
| 333 |    956.833986 |    627.864452 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 334 |    528.022742 |    241.875463 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 335 |    665.692187 |    444.329515 | Chuanixn Yu                                                                                                                                                           |
| 336 |    292.614977 |    706.096073 | C. Camilo Julián-Caballero                                                                                                                                            |
| 337 |    846.870027 |    582.497736 | Christine Axon                                                                                                                                                        |
| 338 |    742.421011 |    670.264330 | Matt Wilkins                                                                                                                                                          |
| 339 |    586.999123 |     40.730781 | Smokeybjb                                                                                                                                                             |
| 340 |    699.412700 |     16.696711 | NA                                                                                                                                                                    |
| 341 |    677.688543 |    335.501345 | Lukasiniho                                                                                                                                                            |
| 342 |   1011.184450 |    339.938512 | Matt Crook                                                                                                                                                            |
| 343 |    447.144486 |    720.036656 | Collin Gross                                                                                                                                                          |
| 344 |    960.510837 |    578.291165 | Aline M. Ghilardi                                                                                                                                                     |
| 345 |    969.490978 |    214.786974 | Chris huh                                                                                                                                                             |
| 346 |    285.363080 |    469.424475 | Margot Michaud                                                                                                                                                        |
| 347 |    758.898754 |    185.841307 | Zimices                                                                                                                                                               |
| 348 |    821.556099 |    374.675338 | Zimices                                                                                                                                                               |
| 349 |    957.612225 |    642.672052 | Ferran Sayol                                                                                                                                                          |
| 350 |    616.562712 |    527.315268 | NA                                                                                                                                                                    |
| 351 |    817.166214 |    249.468456 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 352 |    239.288922 |    280.714435 | Cesar Julian                                                                                                                                                          |
| 353 |     15.925975 |    626.241122 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 354 |    731.639336 |    362.781270 | Matt Crook                                                                                                                                                            |
| 355 |    277.951312 |     96.444013 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                      |
| 356 |    313.463138 |    410.295715 | Margot Michaud                                                                                                                                                        |
| 357 |    402.414202 |    640.046456 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 358 |    226.243672 |     75.506884 | Matt Crook                                                                                                                                                            |
| 359 |    469.493606 |    411.827731 | Jagged Fang Designs                                                                                                                                                   |
| 360 |    275.972707 |    291.077549 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 361 |    418.405655 |    354.074664 | Jagged Fang Designs                                                                                                                                                   |
| 362 |    465.999922 |    126.432116 | Sarah Werning                                                                                                                                                         |
| 363 |   1017.946852 |    194.483165 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 364 |    271.710505 |    232.821655 | Zimices                                                                                                                                                               |
| 365 |    134.009768 |    333.794430 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 366 |    665.011241 |    107.248466 | Zimices                                                                                                                                                               |
| 367 |      9.996044 |    556.918823 | Margot Michaud                                                                                                                                                        |
| 368 |    750.225779 |    595.067517 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
| 369 |    939.483500 |     47.178694 | Steven Traver                                                                                                                                                         |
| 370 |    283.249969 |     55.057463 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
| 371 |    868.987723 |    199.018122 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 372 |     82.004079 |    415.947279 | Mattia Menchetti                                                                                                                                                      |
| 373 |    165.171455 |    527.066916 | Steven Traver                                                                                                                                                         |
| 374 |    898.868925 |    201.845031 | Tasman Dixon                                                                                                                                                          |
| 375 |    493.872597 |    515.558344 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 376 |    101.203610 |    244.005547 | Zimices                                                                                                                                                               |
| 377 |    176.544554 |    693.394545 | T. Michael Keesey                                                                                                                                                     |
| 378 |     72.856759 |    312.354738 | Melissa Broussard                                                                                                                                                     |
| 379 |    841.473213 |    602.637479 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 380 |    800.170377 |    195.581183 | Juan Carlos Jerí                                                                                                                                                      |
| 381 |    445.098320 |     38.403385 | Jagged Fang Designs                                                                                                                                                   |
| 382 |    916.379880 |    122.932643 | Danielle Alba                                                                                                                                                         |
| 383 |    956.105938 |    562.644410 | Anthony Caravaggi                                                                                                                                                     |
| 384 |    243.306590 |    547.056494 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 385 |    987.309295 |    723.165750 | Ferran Sayol                                                                                                                                                          |
| 386 |   1014.660125 |    780.821229 | V. Deepak                                                                                                                                                             |
| 387 |    696.235128 |     28.202483 | FunkMonk                                                                                                                                                              |
| 388 |     16.434987 |    706.328758 | I. Sácek, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
| 389 |    286.775989 |    789.822102 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 390 |    522.115028 |    722.342018 | Jagged Fang Designs                                                                                                                                                   |
| 391 |    645.620539 |    302.833122 | Scott Hartman                                                                                                                                                         |
| 392 |    445.242532 |    133.775331 | Matt Crook                                                                                                                                                            |
| 393 |    384.869761 |    637.232474 | Caleb M. Brown                                                                                                                                                        |
| 394 |    680.579189 |    592.637915 | Martin R. Smith                                                                                                                                                       |
| 395 |    823.140206 |    453.051783 | Gareth Monger                                                                                                                                                         |
| 396 |    194.638300 |     14.167072 | Jonathan Wells                                                                                                                                                        |
| 397 |    658.119060 |    351.426951 | Tasman Dixon                                                                                                                                                          |
| 398 |    776.531944 |    793.161834 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 399 |    450.541954 |    531.032429 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 400 |    230.298785 |    394.595420 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                             |
| 401 |    911.809087 |    781.878829 | Alexandre Vong                                                                                                                                                        |
| 402 |    440.170313 |    430.697778 | Beth Reinke                                                                                                                                                           |
| 403 |    757.359846 |     16.071858 | Jagged Fang Designs                                                                                                                                                   |
| 404 |    467.844659 |    754.053039 | Roberto Díaz Sibaja                                                                                                                                                   |
| 405 |    489.471300 |      6.963227 | Zimices                                                                                                                                                               |
| 406 |    827.692450 |    226.988756 | Ignacio Contreras                                                                                                                                                     |
| 407 |    321.810562 |    120.344058 | xgirouxb                                                                                                                                                              |
| 408 |    398.134579 |    287.132373 | Margot Michaud                                                                                                                                                        |
| 409 |    724.931701 |    693.121971 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 410 |    144.569565 |     63.285870 | Margot Michaud                                                                                                                                                        |
| 411 |    825.457342 |    593.643619 | Gareth Monger                                                                                                                                                         |
| 412 |    392.673911 |    516.564979 | Ingo Braasch                                                                                                                                                          |
| 413 |     24.112696 |    512.370815 | Maxime Dahirel                                                                                                                                                        |
| 414 |    633.806451 |    240.193082 | NA                                                                                                                                                                    |
| 415 |    795.055281 |    134.310164 | Steven Traver                                                                                                                                                         |
| 416 |   1014.726693 |    725.430992 | Richard J. Harris                                                                                                                                                     |
| 417 |    757.007494 |    620.898281 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 418 |    819.357378 |    546.902347 | Ferran Sayol                                                                                                                                                          |
| 419 |    835.357807 |    573.001289 | Harold N Eyster                                                                                                                                                       |
| 420 |    530.874829 |    773.671892 | Kai R. Caspar                                                                                                                                                         |
| 421 |     24.793631 |    488.775836 | Ferran Sayol                                                                                                                                                          |
| 422 |    261.042882 |     44.676230 | Ferran Sayol                                                                                                                                                          |
| 423 |    310.613330 |    399.940047 | Eyal Bartov                                                                                                                                                           |
| 424 |    674.101502 |    499.226132 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 425 |   1003.216548 |    319.998814 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 426 |     96.388264 |    436.115353 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 427 |    673.108534 |    317.565402 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
| 428 |    941.161486 |    230.953463 | Ferran Sayol                                                                                                                                                          |
| 429 |    876.937213 |    577.358397 | Beth Reinke                                                                                                                                                           |
| 430 |    632.771939 |    749.522643 | Josefine Bohr Brask                                                                                                                                                   |
| 431 |    756.431074 |     28.633208 | Meliponicultor Itaymbere                                                                                                                                              |
| 432 |    791.486272 |    597.581478 | Zimices                                                                                                                                                               |
| 433 |    694.436820 |    584.263454 | Gareth Monger                                                                                                                                                         |
| 434 |    602.134200 |    615.791931 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 435 |    787.045942 |    477.139378 | Duane Raver/USFWS                                                                                                                                                     |
| 436 |    482.332689 |    244.213768 | Christine Axon                                                                                                                                                        |
| 437 |    990.007790 |    619.835281 | Zimices                                                                                                                                                               |
| 438 |    158.079826 |    727.146940 | Chris huh                                                                                                                                                             |
| 439 |    514.796427 |    584.227372 | Emma Hughes                                                                                                                                                           |
| 440 |    222.149531 |    561.127516 | Mathew Wedel                                                                                                                                                          |
| 441 |   1011.895101 |    746.265282 | Jaime Headden                                                                                                                                                         |
| 442 |    674.830783 |    672.029451 | Birgit Lang                                                                                                                                                           |
| 443 |    251.189346 |    757.397865 | Markus A. Grohme                                                                                                                                                      |
| 444 |    286.378702 |    254.147356 | Henry Lydecker                                                                                                                                                        |
| 445 |    617.350610 |    363.355783 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 446 |    336.744920 |     19.219038 | Taenadoman                                                                                                                                                            |
| 447 |    638.112364 |    191.436464 | Manabu Sakamoto                                                                                                                                                       |
| 448 |     94.710798 |    339.595053 | Matt Crook                                                                                                                                                            |
| 449 |     48.530668 |      6.418677 | Arthur S. Brum                                                                                                                                                        |
| 450 |    592.819794 |    144.887262 | Ferran Sayol                                                                                                                                                          |
| 451 |    449.219608 |    152.443557 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                 |
| 452 |    139.527782 |    257.543975 | T. Michael Keesey                                                                                                                                                     |
| 453 |   1006.584924 |    159.077431 | Dinah Challen                                                                                                                                                         |
| 454 |    775.369216 |    753.680527 | Michelle Site                                                                                                                                                         |
| 455 |    286.568960 |    203.108569 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 456 |    400.382878 |    133.486340 | Ferran Sayol                                                                                                                                                          |
| 457 |    272.811634 |    584.548707 | Gareth Monger                                                                                                                                                         |
| 458 |    646.281874 |    404.825133 | Maija Karala                                                                                                                                                          |
| 459 |    175.613454 |     12.693354 | Scott Hartman                                                                                                                                                         |
| 460 |    957.389753 |    329.489157 | Steven Traver                                                                                                                                                         |
| 461 |    297.109938 |    507.644090 | Margot Michaud                                                                                                                                                        |
| 462 |    372.898428 |    124.556431 | Armin Reindl                                                                                                                                                          |
| 463 |    350.459905 |    417.421355 | Steven Traver                                                                                                                                                         |
| 464 |    536.381671 |    633.792527 | Becky Barnes                                                                                                                                                          |
| 465 |    157.142465 |    426.418210 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 466 |    883.314765 |     56.291367 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 467 |    793.644918 |    615.083244 | Birgit Lang                                                                                                                                                           |
| 468 |    911.203529 |    447.927886 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                             |
| 469 |    553.736700 |    613.448844 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 470 |    845.707092 |    405.992529 | Emily Willoughby                                                                                                                                                      |
| 471 |    419.327482 |    529.817045 | Birgit Lang                                                                                                                                                           |
| 472 |    297.832266 |    185.602067 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 473 |    480.189877 |     73.011375 | Matt Crook                                                                                                                                                            |
| 474 |    256.240751 |    715.832981 | Mason McNair                                                                                                                                                          |
| 475 |    196.816747 |    772.705818 | Gareth Monger                                                                                                                                                         |
| 476 |    660.860906 |    597.064463 | Jaime Headden                                                                                                                                                         |
| 477 |     58.203947 |    700.807211 | NA                                                                                                                                                                    |
| 478 |    422.099605 |    318.238457 | Scott Hartman                                                                                                                                                         |
| 479 |   1000.362393 |    583.995139 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 480 |    961.042712 |     48.597055 | Kanchi Nanjo                                                                                                                                                          |
| 481 |    787.818228 |    539.436424 | Beth Reinke                                                                                                                                                           |
| 482 |     17.438069 |    208.256186 | Andrew A. Farke                                                                                                                                                       |
| 483 |    686.975784 |    289.678568 | Gareth Monger                                                                                                                                                         |
| 484 |    782.089833 |    482.708125 | Margot Michaud                                                                                                                                                        |
| 485 |    282.796063 |    381.770618 | Michelle Site                                                                                                                                                         |
| 486 |    765.202615 |    132.242528 | Zimices                                                                                                                                                               |
| 487 |    946.673717 |    656.202478 | Christoph Schomburg                                                                                                                                                   |
| 488 |    736.563071 |    231.026098 | Gareth Monger                                                                                                                                                         |
| 489 |    672.596257 |    518.303417 | NA                                                                                                                                                                    |
| 490 |    600.597294 |    205.285697 | V. Deepak                                                                                                                                                             |
| 491 |    994.298149 |     52.896634 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 492 |    660.308199 |    367.102822 | Sarah Werning                                                                                                                                                         |
| 493 |    174.719540 |    784.413006 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 494 |    816.398626 |     45.711779 | NA                                                                                                                                                                    |
| 495 |      9.099503 |    636.974015 | L. Shyamal                                                                                                                                                            |
| 496 |    631.976345 |    443.643521 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 497 |    519.831498 |     59.719130 | Tasman Dixon                                                                                                                                                          |
| 498 |   1007.131298 |    518.350494 | Chris huh                                                                                                                                                             |
| 499 |    156.036407 |    397.364138 | Steven Traver                                                                                                                                                         |
| 500 |    264.371543 |    401.520497 | Margot Michaud                                                                                                                                                        |
| 501 |    681.971286 |    627.848540 | Ferran Sayol                                                                                                                                                          |
| 502 |    193.705092 |    663.613393 | L. Shyamal                                                                                                                                                            |
| 503 |    340.847628 |    453.950003 | Matt Crook                                                                                                                                                            |
| 504 |    769.728438 |    158.521819 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 505 |     40.749643 |    141.637019 | terngirl                                                                                                                                                              |
| 506 |    215.483111 |    782.262256 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 507 |    585.401828 |    491.367332 | Markus A. Grohme                                                                                                                                                      |
| 508 |    210.197736 |    750.032080 | Gareth Monger                                                                                                                                                         |
| 509 |    750.293736 |    324.736153 | Frank Förster                                                                                                                                                         |
| 510 |    319.313142 |    362.227206 | RS                                                                                                                                                                    |
| 511 |    201.606518 |    506.755373 | Jagged Fang Designs                                                                                                                                                   |
| 512 |    310.265412 |    156.420296 | Matt Martyniuk                                                                                                                                                        |
| 513 |    313.449827 |    446.321730 | Mathieu Basille                                                                                                                                                       |
| 514 |     34.486675 |    499.175432 | Joedison Rocha                                                                                                                                                        |
| 515 |      7.900602 |    372.626780 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 516 |    859.048573 |    782.457562 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 517 |    356.358453 |    184.066032 | NA                                                                                                                                                                    |
| 518 |    447.044178 |    514.670973 | Zimices                                                                                                                                                               |
| 519 |    150.716516 |    625.151245 | Daniel Stadtmauer                                                                                                                                                     |
| 520 |    111.862085 |    263.338299 | Matt Crook                                                                                                                                                            |
| 521 |    136.744230 |    436.313378 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 522 |    306.695207 |    386.293125 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                           |
| 523 |    375.435041 |    378.023948 | Zimices                                                                                                                                                               |
| 524 |    807.659322 |    185.275356 | Amanda Katzer                                                                                                                                                         |
| 525 |    174.916194 |    495.817069 | Kent Elson Sorgon                                                                                                                                                     |
| 526 |    851.635506 |    411.421877 | Chris huh                                                                                                                                                             |
| 527 |    748.429696 |    404.351720 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 528 |     46.883600 |    186.734032 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 529 |    110.567003 |    513.245202 | Matt Crook                                                                                                                                                            |
| 530 |    544.283570 |    201.021430 | Matt Crook                                                                                                                                                            |
| 531 |    665.892432 |    557.802288 | Matt Crook                                                                                                                                                            |
| 532 |    779.152492 |     44.208473 | Gareth Monger                                                                                                                                                         |
| 533 |    870.525497 |     87.989083 | FunkMonk                                                                                                                                                              |
| 534 |   1002.236086 |    430.992112 | Abraão Leite                                                                                                                                                          |
| 535 |    986.964739 |    364.142670 | Birgit Lang                                                                                                                                                           |
| 536 |    669.950078 |    158.953491 | Alex Slavenko                                                                                                                                                         |
| 537 |    803.887647 |    534.756290 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 538 |    656.319706 |    294.572311 | Joanna Wolfe                                                                                                                                                          |
| 539 |     45.440132 |    579.560134 | NA                                                                                                                                                                    |
| 540 |    261.523758 |    579.198019 | Michelle Site                                                                                                                                                         |
| 541 |    471.888564 |    375.882221 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 542 |    964.481065 |    119.790844 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 543 |    921.860531 |    108.478086 | Chris huh                                                                                                                                                             |
| 544 |    344.421507 |    665.728940 | SecretJellyMan                                                                                                                                                        |
| 545 |    830.185996 |    661.151658 | Mathilde Cordellier                                                                                                                                                   |
| 546 |    455.200728 |    316.149159 | Kamil S. Jaron                                                                                                                                                        |
| 547 |    877.717094 |    561.062197 | Chris huh                                                                                                                                                             |
| 548 |    453.682846 |    738.349780 | Roberto Díaz Sibaja                                                                                                                                                   |
| 549 |    767.767854 |    334.508708 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 550 |    663.607661 |    169.079485 | Zimices                                                                                                                                                               |
| 551 |    829.191193 |    586.686472 | Tasman Dixon                                                                                                                                                          |
| 552 |     21.455988 |    229.544609 | Smokeybjb                                                                                                                                                             |
| 553 |    942.113437 |    751.334088 | Jagged Fang Designs                                                                                                                                                   |
| 554 |    218.201740 |     24.784921 | Tyler McCraney                                                                                                                                                        |
| 555 |    564.342576 |    605.282297 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 556 |    265.703971 |      3.532269 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 557 |    549.481924 |    643.931123 | NA                                                                                                                                                                    |
| 558 |    582.611337 |    683.009331 | mystica                                                                                                                                                               |
| 559 |     21.677663 |    747.437432 | Steven Traver                                                                                                                                                         |
| 560 |    915.133962 |    643.193549 | Chris A. Hamilton                                                                                                                                                     |
| 561 |    101.810497 |    487.276606 | NA                                                                                                                                                                    |
| 562 |    889.132155 |    417.198708 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 563 |    744.629344 |    142.330810 | Chris huh                                                                                                                                                             |
| 564 |     79.923399 |    376.512362 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 565 |     13.898438 |    608.630835 | Margot Michaud                                                                                                                                                        |
| 566 |    385.837099 |    120.009371 | NA                                                                                                                                                                    |
| 567 |    540.281178 |    786.435719 | Jack Mayer Wood                                                                                                                                                       |
| 568 |    208.885199 |    568.603940 | Zimices                                                                                                                                                               |
| 569 |    895.415960 |    677.540469 | Gareth Monger                                                                                                                                                         |
| 570 |   1001.597317 |    186.756687 | Chuanixn Yu                                                                                                                                                           |
| 571 |    285.253044 |    127.637227 | Steven Traver                                                                                                                                                         |
| 572 |    894.552495 |    706.684397 | Dexter R. Mardis                                                                                                                                                      |
| 573 |    692.785433 |    595.623614 | Gareth Monger                                                                                                                                                         |
| 574 |    488.979600 |    183.942478 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 575 |    345.806943 |    354.740358 | Chris huh                                                                                                                                                             |
| 576 |    872.846137 |    354.928805 | Birgit Lang                                                                                                                                                           |
| 577 |    278.272249 |    548.801413 | Matt Crook                                                                                                                                                            |
| 578 |    153.614984 |      4.085427 | Zimices                                                                                                                                                               |
| 579 |    793.898982 |    462.838669 | NA                                                                                                                                                                    |
| 580 |    700.863757 |    343.922707 | François Michonneau                                                                                                                                                   |
| 581 |      6.300865 |    226.714934 | Joanna Wolfe                                                                                                                                                          |
| 582 |    689.284075 |    439.761583 | Tyler Greenfield                                                                                                                                                      |
| 583 |    846.543406 |    106.331288 | Zimices                                                                                                                                                               |
| 584 |     89.192899 |     53.458298 | Ferran Sayol                                                                                                                                                          |
| 585 |    310.154499 |    326.111924 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 586 |    790.617570 |    646.371821 | Scott Hartman                                                                                                                                                         |
| 587 |   1016.365934 |    442.252736 | Gareth Monger                                                                                                                                                         |
| 588 |    922.356452 |    454.117623 | NA                                                                                                                                                                    |
| 589 |    593.704153 |     20.245897 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 590 |    607.900189 |    393.639751 | Margot Michaud                                                                                                                                                        |
| 591 |    231.690419 |    611.932686 | T. Michael Keesey                                                                                                                                                     |
| 592 |    264.225507 |     84.508430 | Matt Crook                                                                                                                                                            |
| 593 |    288.320705 |    390.423291 | Ferran Sayol                                                                                                                                                          |
| 594 |    855.426599 |    654.158482 | Gareth Monger                                                                                                                                                         |
| 595 |    149.005912 |    685.810820 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 596 |   1009.092401 |     17.862793 | NA                                                                                                                                                                    |
| 597 |    825.002213 |     29.398299 | Pete Buchholz                                                                                                                                                         |
| 598 |    870.328289 |    126.069436 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 599 |    434.370949 |    338.545425 | Gareth Monger                                                                                                                                                         |
| 600 |    894.911625 |     10.752206 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 601 |    412.917602 |    332.423268 | Gareth Monger                                                                                                                                                         |
| 602 |    846.971797 |    564.766150 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 603 |    598.554812 |    296.866288 | Zimices                                                                                                                                                               |
| 604 |    545.854580 |    596.703105 | Steven Traver                                                                                                                                                         |
| 605 |    287.858089 |    369.323839 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 606 |    883.669111 |    254.202705 | Margot Michaud                                                                                                                                                        |
| 607 |    898.217730 |    357.277155 | Zimices                                                                                                                                                               |
| 608 |    226.424317 |    706.148566 | Michael P. Taylor                                                                                                                                                     |
| 609 |    595.477269 |    364.794406 | T. Michael Keesey                                                                                                                                                     |
| 610 |    902.608201 |    394.474750 | Andrew A. Farke                                                                                                                                                       |
| 611 |    462.195554 |    763.240645 | Margot Michaud                                                                                                                                                        |
| 612 |    386.286755 |    110.684006 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 613 |    134.257661 |    540.135050 | Kanchi Nanjo                                                                                                                                                          |
| 614 |    324.374818 |     22.596960 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 615 |    508.052931 |    251.228329 | NA                                                                                                                                                                    |
| 616 |    789.453454 |    312.066528 | Katie S. Collins                                                                                                                                                      |
| 617 |    774.330741 |    506.377005 | Emily Willoughby                                                                                                                                                      |
| 618 |    448.561398 |    524.886482 | Zimices                                                                                                                                                               |
| 619 |    391.766744 |     99.407155 | Matt Crook                                                                                                                                                            |
| 620 |    827.893639 |    533.680038 | Michelle Site                                                                                                                                                         |
| 621 |    136.644296 |    713.993188 | Matt Crook                                                                                                                                                            |
| 622 |    516.136728 |    706.509530 | Tasman Dixon                                                                                                                                                          |
| 623 |    978.727818 |     15.110065 | T. Michael Keesey                                                                                                                                                     |
| 624 |    976.896826 |    375.496209 | Ignacio Contreras                                                                                                                                                     |
| 625 |    817.475665 |    430.262642 | Matt Crook                                                                                                                                                            |
| 626 |    981.784106 |    792.557118 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 627 |    666.594136 |    238.154253 | NA                                                                                                                                                                    |
| 628 |     72.254731 |    129.935553 | Sarah Werning                                                                                                                                                         |
| 629 |    614.941131 |    261.780987 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 630 |    277.415021 |    239.363760 | Jagged Fang Designs                                                                                                                                                   |
| 631 |    538.730850 |    370.354702 | Melissa Broussard                                                                                                                                                     |
| 632 |    724.560831 |    672.173229 | Chris huh                                                                                                                                                             |
| 633 |    249.318123 |    427.628788 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 634 |    388.637676 |    188.640617 | Steven Coombs                                                                                                                                                         |
| 635 |     20.465653 |    336.671121 | Jagged Fang Designs                                                                                                                                                   |
| 636 |      9.876047 |    696.938810 | Gareth Monger                                                                                                                                                         |
| 637 |    704.903917 |    603.603533 | Andrew A. Farke                                                                                                                                                       |
| 638 |    684.522995 |    245.113032 | Steven Traver                                                                                                                                                         |
| 639 |    483.979605 |    600.279667 | Gareth Monger                                                                                                                                                         |
| 640 |    726.615133 |    474.900056 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 641 |    116.156099 |    793.867880 | Jagged Fang Designs                                                                                                                                                   |
| 642 |    191.799855 |    513.465023 | Ignacio Contreras                                                                                                                                                     |
| 643 |    408.984159 |    614.049144 | Margot Michaud                                                                                                                                                        |
| 644 |    289.970268 |    690.066827 | Scott Reid                                                                                                                                                            |
| 645 |    870.533163 |    236.821477 | kotik                                                                                                                                                                 |
| 646 |     73.823011 |    449.832786 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 647 |    889.717569 |    324.742870 | Matt Crook                                                                                                                                                            |
| 648 |    596.066272 |    513.610674 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 649 |    765.268929 |    522.100544 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 650 |    455.334756 |    650.690750 | David Orr                                                                                                                                                             |
| 651 |    239.604921 |     32.087911 | Birgit Lang                                                                                                                                                           |
| 652 |    755.637688 |    294.857143 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 653 |    763.997096 |    112.950498 | Lukasiniho                                                                                                                                                            |
| 654 |    253.671363 |    784.181404 | Dean Schnabel                                                                                                                                                         |
| 655 |    965.390921 |    768.718384 | V. Deepak                                                                                                                                                             |
| 656 |    670.615413 |    347.820892 | Margot Michaud                                                                                                                                                        |
| 657 |    944.807917 |    387.718655 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 658 |    688.397837 |    662.661542 | T. Michael Keesey                                                                                                                                                     |
| 659 |    690.938874 |    275.069765 | Sharon Wegner-Larsen                                                                                                                                                  |
| 660 |    211.836699 |    636.039503 | Melissa Broussard                                                                                                                                                     |
| 661 |    913.273042 |    320.341371 | Steven Traver                                                                                                                                                         |
| 662 |   1009.614810 |    134.377353 | FunkMonk                                                                                                                                                              |
| 663 |    753.174640 |    662.216707 | Bruno C. Vellutini                                                                                                                                                    |
| 664 |    876.015952 |    338.322208 | Rebecca Groom                                                                                                                                                         |
| 665 |    116.164738 |    700.321112 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 666 |    981.847926 |    183.008895 | Tasman Dixon                                                                                                                                                          |
| 667 |    979.529027 |    642.406002 | Terpsichores                                                                                                                                                          |
| 668 |    712.871285 |    161.907249 | Zimices                                                                                                                                                               |
| 669 |    558.737160 |    497.278279 | Melissa Broussard                                                                                                                                                     |
| 670 |    628.327163 |    405.143394 | NA                                                                                                                                                                    |
| 671 |    809.332738 |    324.507792 | Jagged Fang Designs                                                                                                                                                   |
| 672 |    286.584547 |    616.298306 | NA                                                                                                                                                                    |
| 673 |      8.740882 |    540.151383 | Christoph Schomburg                                                                                                                                                   |
| 674 |    272.254535 |    435.347302 | Tyler Greenfield                                                                                                                                                      |
| 675 |    524.077080 |    600.628239 | Gareth Monger                                                                                                                                                         |
| 676 |     18.242570 |    361.825672 | Zimices                                                                                                                                                               |
| 677 |    473.617280 |    402.953013 | Steven Traver                                                                                                                                                         |
| 678 |    512.095891 |     81.059981 | C. Camilo Julián-Caballero                                                                                                                                            |
| 679 |    559.766076 |     35.267968 | NA                                                                                                                                                                    |
| 680 |    859.336464 |    318.738051 | Gareth Monger                                                                                                                                                         |
| 681 |    248.144725 |     46.476683 | L.M. Davalos                                                                                                                                                          |
| 682 |    465.411840 |    517.348987 | Kevin Sánchez                                                                                                                                                         |
| 683 |    478.303103 |    117.817984 | Zimices                                                                                                                                                               |
| 684 |   1009.026660 |    707.540511 | Ferran Sayol                                                                                                                                                          |
| 685 |    318.486326 |    710.490734 | Caleb M. Brown                                                                                                                                                        |
| 686 |    885.118426 |    123.939193 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 687 |     64.320001 |    475.487874 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
| 688 |    317.681741 |    499.881605 | Ferran Sayol                                                                                                                                                          |
| 689 |    737.745156 |    700.604031 | NA                                                                                                                                                                    |
| 690 |    597.430149 |    721.370102 | T. K. Robinson                                                                                                                                                        |
| 691 |    127.486929 |    519.356586 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 692 |    193.579908 |    735.819275 | L. Shyamal                                                                                                                                                            |
| 693 |    402.695116 |    223.018158 | Jaime Headden                                                                                                                                                         |
| 694 |    190.500430 |    784.368767 | Darius Nau                                                                                                                                                            |
| 695 |    733.165798 |     33.198402 | Steven Traver                                                                                                                                                         |
| 696 |    756.924629 |    793.064970 | Zimices                                                                                                                                                               |
| 697 |     77.169155 |     69.144807 | Mykle Hoban                                                                                                                                                           |
| 698 |    962.792479 |      9.379679 | Sarah Werning                                                                                                                                                         |
| 699 |    399.200625 |    303.971376 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 700 |     55.884527 |    146.054741 | Steven Coombs                                                                                                                                                         |
| 701 |    277.416399 |    726.102156 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 702 |    321.569285 |    341.386357 | Matt Crook                                                                                                                                                            |
| 703 |    672.967344 |    659.487776 | Markus A. Grohme                                                                                                                                                      |
| 704 |    134.718004 |    461.550481 | Zimices                                                                                                                                                               |
| 705 |    598.845623 |    625.616608 | Manabu Sakamoto                                                                                                                                                       |
| 706 |    293.823836 |    580.538811 | Zimices                                                                                                                                                               |
| 707 |    903.268210 |    744.876636 | Steven Traver                                                                                                                                                         |
| 708 |    714.397030 |    322.669535 | L. Shyamal                                                                                                                                                            |
| 709 |     29.839055 |    774.027709 | NA                                                                                                                                                                    |
| 710 |    998.308024 |    533.383115 | Milton Tan                                                                                                                                                            |
| 711 |     16.361516 |    148.189003 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 712 |    648.590926 |    459.399087 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 713 |    789.907176 |    114.488893 | Andrés Sánchez                                                                                                                                                        |
| 714 |    130.767947 |    611.827542 | Margot Michaud                                                                                                                                                        |
| 715 |    660.921762 |    183.093137 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 716 |    850.373768 |    346.124395 | Birgit Lang                                                                                                                                                           |
| 717 |    613.392094 |    191.313141 | Margot Michaud                                                                                                                                                        |
| 718 |    471.044293 |    502.910444 | Matt Crook                                                                                                                                                            |
| 719 |    736.887954 |    585.417981 | Maxime Dahirel                                                                                                                                                        |
| 720 |    592.536064 |     53.064440 | Tasman Dixon                                                                                                                                                          |
| 721 |    921.918746 |    182.307847 | Cathy                                                                                                                                                                 |
| 722 |    992.374711 |    333.899945 | Joanna Wolfe                                                                                                                                                          |
| 723 |    900.975701 |    174.261949 | Margot Michaud                                                                                                                                                        |
| 724 |    641.984474 |    684.242152 | Karla Martinez                                                                                                                                                        |
| 725 |    410.443903 |    514.504216 | Margot Michaud                                                                                                                                                        |
| 726 |    997.167900 |      7.807334 | Noah Schlottman                                                                                                                                                       |
| 727 |    982.702019 |    351.978705 | Tasman Dixon                                                                                                                                                          |
| 728 |    779.127896 |    116.481428 | T. Michael Keesey                                                                                                                                                     |
| 729 |    603.961122 |    172.388174 | terngirl                                                                                                                                                              |
| 730 |    548.939981 |    503.356254 | Markus A. Grohme                                                                                                                                                      |
| 731 |    280.397856 |    515.303134 | Scott Reid                                                                                                                                                            |
| 732 |    221.594495 |    607.244503 | Rachel Shoop                                                                                                                                                          |
| 733 |    503.124983 |     74.523096 | Jagged Fang Designs                                                                                                                                                   |
| 734 |    528.918474 |    647.229212 | Yan Wong                                                                                                                                                              |
| 735 |    330.269631 |    776.579366 | Chris Jennings (Risiatto)                                                                                                                                             |
| 736 |    874.733427 |    706.561029 | Jagged Fang Designs                                                                                                                                                   |
| 737 |    604.142373 |    163.469015 | Chris huh                                                                                                                                                             |
| 738 |     11.858421 |    455.755282 | Gareth Monger                                                                                                                                                         |
| 739 |    214.644090 |    793.016387 | Gareth Monger                                                                                                                                                         |
| 740 |    280.889226 |    530.405312 | Tasman Dixon                                                                                                                                                          |
| 741 |    995.538224 |    646.302807 | Steven Traver                                                                                                                                                         |
| 742 |    592.177587 |    594.801083 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 743 |   1005.908058 |    212.285968 | Scott Hartman                                                                                                                                                         |
| 744 |    989.092256 |    664.046282 | Jaime Headden                                                                                                                                                         |
| 745 |    295.858741 |    566.794185 | Crystal Maier                                                                                                                                                         |
| 746 |    193.112117 |    615.860588 | Steven Traver                                                                                                                                                         |
| 747 |    533.996795 |    587.757940 | CNZdenek                                                                                                                                                              |
| 748 |     17.868118 |     45.814856 | Scott Hartman                                                                                                                                                         |
| 749 |    985.257128 |    775.883867 | NA                                                                                                                                                                    |
| 750 |    172.840091 |    766.228288 | Peileppe                                                                                                                                                              |
| 751 |    516.952571 |    646.117169 | Tasman Dixon                                                                                                                                                          |
| 752 |    702.038980 |    481.927281 | Ferran Sayol                                                                                                                                                          |
| 753 |     72.484115 |    190.665698 | Rebecca Groom                                                                                                                                                         |
| 754 |    701.099919 |    235.419776 | Jonathan Wells                                                                                                                                                        |
| 755 |    469.084250 |    525.057009 | Martin R. Smith                                                                                                                                                       |
| 756 |    689.782590 |    563.970738 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 757 |    330.582382 |    526.070961 | Jaime Headden                                                                                                                                                         |
| 758 |    712.025462 |    365.473008 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
| 759 |    152.579254 |    638.827937 | Smokeybjb                                                                                                                                                             |
| 760 |    700.214226 |    660.850794 | Matt Celeskey                                                                                                                                                         |
| 761 |     15.258423 |    659.407921 | Markus A. Grohme                                                                                                                                                      |
| 762 |    580.949165 |    693.145501 | Cesar Julian                                                                                                                                                          |
| 763 |   1009.382910 |    604.894473 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 764 |    154.616014 |    770.017265 | Gareth Monger                                                                                                                                                         |
| 765 |     45.567406 |    489.567926 | Gareth Monger                                                                                                                                                         |
| 766 |    127.579177 |    260.074417 | Alexandre Vong                                                                                                                                                        |
| 767 |    275.094152 |    455.559680 | Margot Michaud                                                                                                                                                        |
| 768 |    709.356900 |    593.780972 | Steven Traver                                                                                                                                                         |
| 769 |    234.888665 |    744.784645 | NA                                                                                                                                                                    |
| 770 |    102.779875 |     11.257962 | Oscar Sanisidro                                                                                                                                                       |
| 771 |    322.022181 |    130.770150 | Steven Traver                                                                                                                                                         |
| 772 |    973.627034 |    609.840008 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 773 |    657.782145 |     35.728591 | Juan Carlos Jerí                                                                                                                                                      |
| 774 |   1015.410320 |    145.993078 | Markus A. Grohme                                                                                                                                                      |
| 775 |    494.533632 |    356.582421 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 776 |    976.547854 |    330.829756 | Gareth Monger                                                                                                                                                         |
| 777 |    772.819256 |     29.137222 | Matt Crook                                                                                                                                                            |
| 778 |    923.297842 |    612.730359 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 779 |    143.798863 |    538.694442 | Mathieu Basille                                                                                                                                                       |
| 780 |   1011.883523 |    673.922077 | Jagged Fang Designs                                                                                                                                                   |
| 781 |    487.259140 |    464.677302 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 782 |    629.487578 |    780.309681 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 783 |     29.591235 |    158.120997 | Margot Michaud                                                                                                                                                        |
| 784 |    556.783479 |    716.920576 | Gareth Monger                                                                                                                                                         |
| 785 |    992.453282 |    309.574539 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 786 |    112.232451 |    441.063800 | Margot Michaud                                                                                                                                                        |
| 787 |     73.876552 |    779.467889 | Terpsichores                                                                                                                                                          |
| 788 |    267.409417 |    322.122690 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 789 |    375.332847 |     50.474322 | Margot Michaud                                                                                                                                                        |
| 790 |    854.485557 |    122.610842 | Owen Jones                                                                                                                                                            |
| 791 |   1018.891600 |    173.946109 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 792 |    972.666166 |    321.867304 | Michelle Site                                                                                                                                                         |
| 793 |    757.727932 |    578.489613 | Scott Hartman                                                                                                                                                         |
| 794 |    389.767196 |    277.336603 | Emily Willoughby                                                                                                                                                      |
| 795 |    946.537505 |    470.321020 | NA                                                                                                                                                                    |
| 796 |    484.224169 |     29.899683 | Chris huh                                                                                                                                                             |
| 797 |    378.464649 |    262.516075 | Matt Crook                                                                                                                                                            |
| 798 |    227.433554 |      8.914321 | Chris huh                                                                                                                                                             |
| 799 |    123.281861 |    360.151501 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 800 |    790.243905 |    438.081055 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 801 |    772.130642 |    496.015101 | Ignacio Contreras                                                                                                                                                     |
| 802 |    785.596345 |    583.572006 | Lauren Sumner-Rooney                                                                                                                                                  |
| 803 |    632.717712 |    135.203250 | Yan Wong                                                                                                                                                              |
| 804 |    929.854551 |    547.737308 | NA                                                                                                                                                                    |
| 805 |    447.863113 |    635.600463 | Iain Reid                                                                                                                                                             |
| 806 |    146.758944 |    404.766292 | Ferran Sayol                                                                                                                                                          |
| 807 |     81.742222 |    702.922012 | Margot Michaud                                                                                                                                                        |
| 808 |    914.192511 |    311.833688 | Chris huh                                                                                                                                                             |
| 809 |    630.363563 |    115.594013 | Beth Reinke                                                                                                                                                           |
| 810 |    281.212453 |    568.580425 | L. Shyamal                                                                                                                                                            |
| 811 |    975.408998 |    119.069516 | Margot Michaud                                                                                                                                                        |
| 812 |    633.043825 |    465.588241 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 813 |    551.309859 |     28.431125 | G. M. Woodward                                                                                                                                                        |
| 814 |    818.851542 |    214.231424 | L.M. Davalos                                                                                                                                                          |
| 815 |    118.705573 |    385.869958 | Steven Traver                                                                                                                                                         |
| 816 |    414.408813 |    428.921333 | Lily Hughes                                                                                                                                                           |
| 817 |   1010.967793 |    486.735935 | Pete Buchholz                                                                                                                                                         |
| 818 |    128.556913 |    525.981119 | Jaime Headden                                                                                                                                                         |
| 819 |    535.684316 |    342.663098 | Scott Hartman                                                                                                                                                         |
| 820 |    588.279739 |     30.748819 | Ferran Sayol                                                                                                                                                          |
| 821 |   1011.911846 |     93.605161 | Zimices                                                                                                                                                               |
| 822 |     26.788334 |    466.379809 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 823 |    620.734496 |    421.015791 | Tasman Dixon                                                                                                                                                          |
| 824 |    713.036242 |    510.673461 | Margot Michaud                                                                                                                                                        |
| 825 |    310.983362 |    315.050995 | Maija Karala                                                                                                                                                          |
| 826 |    744.673228 |    149.741078 | Zimices                                                                                                                                                               |
| 827 |    859.301168 |    588.728848 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 828 |    515.334394 |    183.812951 | T. Michael Keesey                                                                                                                                                     |
| 829 |    164.022086 |    621.913666 | Margot Michaud                                                                                                                                                        |
| 830 |    881.116417 |     24.593850 | T. Tischler                                                                                                                                                           |
| 831 |    541.374039 |    743.493572 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 832 |    804.262707 |    624.981109 | Ferran Sayol                                                                                                                                                          |
| 833 |     13.516431 |    240.693884 | Chris Jennings (Risiatto)                                                                                                                                             |
| 834 |    267.204578 |    746.347347 | C. Camilo Julián-Caballero                                                                                                                                            |
| 835 |    549.458099 |    793.242285 | Caleb M. Brown                                                                                                                                                        |
| 836 |    420.863132 |    696.689164 | Anthony Caravaggi                                                                                                                                                     |
| 837 |    201.925953 |    646.159800 | Scott Hartman                                                                                                                                                         |
| 838 |    734.762930 |    332.622486 | Margot Michaud                                                                                                                                                        |
| 839 |    970.854608 |    490.789520 | Matt Crook                                                                                                                                                            |
| 840 |    334.047637 |    532.207084 | Zimices                                                                                                                                                               |
| 841 |    457.780842 |    677.153015 | G. M. Woodward                                                                                                                                                        |
| 842 |    944.602430 |    553.219565 | Chris huh                                                                                                                                                             |
| 843 |    862.724119 |    250.003613 | Matt Crook                                                                                                                                                            |
| 844 |     65.684225 |    109.678646 | Liftarn                                                                                                                                                               |
| 845 |    435.453468 |    622.907753 | Jagged Fang Designs                                                                                                                                                   |
| 846 |    422.516387 |    513.213494 | Gareth Monger                                                                                                                                                         |
| 847 |    469.170253 |    686.186962 | Emily Willoughby                                                                                                                                                      |
| 848 |    106.258915 |    711.052548 | FunkMonk                                                                                                                                                              |
| 849 |    274.019633 |    377.891656 | Matt Crook                                                                                                                                                            |
| 850 |    733.553472 |    781.306009 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 851 |    264.191259 |    598.280457 | Gareth Monger                                                                                                                                                         |
| 852 |    197.963709 |    598.377745 | Zimices                                                                                                                                                               |
| 853 |    122.441263 |    620.474551 | NA                                                                                                                                                                    |
| 854 |    385.443363 |    763.330713 | Frank Förster                                                                                                                                                         |
| 855 |    612.180717 |     87.197728 | Jagged Fang Designs                                                                                                                                                   |
| 856 |    459.753012 |    461.110209 | NA                                                                                                                                                                    |
| 857 |    708.786333 |    294.649895 | Matt Crook                                                                                                                                                            |
| 858 |    958.723605 |    182.949634 | Margot Michaud                                                                                                                                                        |
| 859 |    129.611144 |    473.186841 | Ferran Sayol                                                                                                                                                          |
| 860 |    290.176111 |    518.877935 | Gareth Monger                                                                                                                                                         |
| 861 |    777.656126 |    631.832836 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 862 |    420.618876 |    603.834320 | Peileppe                                                                                                                                                              |
| 863 |    504.421618 |    635.335829 | Konsta Happonen                                                                                                                                                       |
| 864 |    464.720446 |    584.072093 | Kamil S. Jaron                                                                                                                                                        |
| 865 |    164.598582 |    429.675123 | NA                                                                                                                                                                    |
| 866 |     20.842670 |    764.921645 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 867 |    672.145327 |    424.659799 | Matt Crook                                                                                                                                                            |
| 868 |    577.370320 |    124.466149 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 869 |    639.368807 |    423.023827 | Juan Carlos Jerí                                                                                                                                                      |
| 870 |    178.169765 |    673.252992 | FunkMonk                                                                                                                                                              |
| 871 |    439.297452 |    378.204626 | Chris huh                                                                                                                                                             |
| 872 |    429.779552 |    398.215482 | NA                                                                                                                                                                    |
| 873 |    639.683998 |    267.015519 | Felix Vaux                                                                                                                                                            |
| 874 |    673.906415 |    571.849985 | Neil Kelley                                                                                                                                                           |
| 875 |    860.371742 |     93.879875 | Margot Michaud                                                                                                                                                        |
| 876 |    916.757085 |    520.175928 | Maija Karala                                                                                                                                                          |
| 877 |    760.342065 |    258.355010 | NA                                                                                                                                                                    |
| 878 |    880.149527 |    271.758708 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 879 |    573.512555 |     19.396434 | NA                                                                                                                                                                    |
| 880 |    104.602084 |    454.668664 | Kanchi Nanjo                                                                                                                                                          |
| 881 |    892.951035 |    163.821673 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 882 |    894.654308 |     50.844077 | M Kolmann                                                                                                                                                             |
| 883 |    730.138628 |    306.110680 | Chris huh                                                                                                                                                             |
| 884 |    676.549715 |    328.411206 | Chris huh                                                                                                                                                             |
| 885 |    473.586247 |    112.443950 | Emily Willoughby                                                                                                                                                      |
| 886 |    226.383321 |    581.100074 | NA                                                                                                                                                                    |
| 887 |    459.580037 |    335.351474 | Matt Crook                                                                                                                                                            |
| 888 |    637.279034 |    162.412052 | T. Michael Keesey                                                                                                                                                     |
| 889 |    325.948507 |    723.189262 | T. Michael Keesey                                                                                                                                                     |
| 890 |    825.276880 |    546.031397 | Félix Landry Yuan                                                                                                                                                     |
| 891 |    743.211355 |    369.717736 | T. Michael Keesey                                                                                                                                                     |
| 892 |    807.362177 |    452.942484 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 893 |     82.603882 |    762.055794 | Collin Gross                                                                                                                                                          |
| 894 |    663.438693 |    670.887253 | Pete Buchholz                                                                                                                                                         |
| 895 |    963.645906 |    790.862006 | Zimices                                                                                                                                                               |
| 896 |    767.675094 |    662.254575 | Martin R. Smith                                                                                                                                                       |
| 897 |     13.625702 |    168.431802 | Ferran Sayol                                                                                                                                                          |
| 898 |    336.929792 |    517.179601 | T. Michael Keesey                                                                                                                                                     |
| 899 |    312.903215 |    373.241776 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 900 |    316.022609 |    535.672284 | Taro Maeda                                                                                                                                                            |
| 901 |    259.573553 |    361.630450 | Zachary Quigley                                                                                                                                                       |
| 902 |    480.765852 |    235.435819 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 903 |    201.783509 |    408.752353 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 904 |    519.856616 |    628.947924 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                              |
| 905 |    139.515143 |    452.163535 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
| 906 |    268.968982 |    706.599244 | Renata F. Martins                                                                                                                                                     |
| 907 |    333.192897 |    281.053630 | TaraTaylorDesign                                                                                                                                                      |
| 908 |    238.377346 |    582.595246 | T. Michael Keesey                                                                                                                                                     |
| 909 |    672.750284 |    580.424352 | Matt Crook                                                                                                                                                            |
| 910 |    737.006388 |    490.187638 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 911 |    584.777010 |    606.746344 | FunkMonk                                                                                                                                                              |
| 912 |   1019.312389 |    211.463717 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 913 |    164.020419 |    250.233786 | Tasman Dixon                                                                                                                                                          |
| 914 |    212.881915 |    268.267396 | Jaime Headden                                                                                                                                                         |
| 915 |    893.746448 |    256.688833 | Margot Michaud                                                                                                                                                        |
| 916 |    398.273221 |    143.273624 | T. Michael Keesey                                                                                                                                                     |
| 917 |    180.995117 |    254.118103 | Felix Vaux                                                                                                                                                            |
| 918 |    839.114669 |    243.391726 | Pete Buchholz                                                                                                                                                         |
| 919 |    644.293858 |    757.388867 | Carlos Cano-Barbacil                                                                                                                                                  |

    #> Your tweet has been posted!
