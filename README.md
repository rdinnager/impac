
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immosaic

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/immosaic/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/immosaic/actions)
<!-- badges: end -->

The goal of `{immosaic}` is to create packed image mosaics. The main
function `immosaic`, takes a set of images, or a function that generates
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
devtools::install_github("rdinnager/immosaic")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(immosaic)
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

Now we feed our function to the `immosaic()` function, which packs the
generated images onto a canvas:

``` r
shapes <- immosaic(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
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

Now we run `immosaic` on our phylopic generating function:

``` r
phylopics <- immosaic(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Emily Willoughby, Chloé Schmidt, Beth Reinke, Ferran Sayol, Cesar
Julian, Scott Reid, Tauana J. Cunha, Tony Ayling (vectorized by T.
Michael Keesey), Martin R. Smith, Jean-Raphaël Guillaumin (photography)
and T. Michael Keesey (vectorization), Matt Crook, T. Michael Keesey
(vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), Trond R. Oskars, Dean Schnabel, Jose
Carlos Arenas-Monroy, Yan Wong from drawing in The Century Dictionary
(1911), Chris huh, Yan Wong, Joseph Wolf, 1863 (vectorization by Dinah
Challen), Dmitry Bogdanov (vectorized by T. Michael Keesey), Matthew E.
Clapham, Xavier Giroux-Bougard, Joanna Wolfe, Zimices, Carlos
Cano-Barbacil, Keith Murdock (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Birgit Lang, Scott Hartman, John Gould
(vectorized by T. Michael Keesey), Christoph Schomburg, Smokeybjb
(modified by Mike Keesey), Tasman Dixon, Jiekun He, Margot Michaud, Nobu
Tamura (vectorized by T. Michael Keesey), Marie Russell, Chris Jennings
(Risiatto), Noah Schlottman, photo by Museum of Geology, University of
Tartu, Gareth Monger, Chase Brownstein, James I. Kirkland, Luis Alcalá,
Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), Jagged Fang Designs, Servien
(vectorized by T. Michael Keesey), Yan Wong from photo by Denes Emoke,
Chris Hay, Mattia Menchetti, Darren Naish (vectorize by T. Michael
Keesey), terngirl, Steven Coombs, (after Spotila 2004), C. Camilo
Julián-Caballero, T. Michael Keesey (after Mauricio Antón), Jaime
Headden, Yan Wong (vectorization) from 1873 illustration, Obsidian Soul
(vectorized by T. Michael Keesey), Iain Reid, Ghedoghedo, Maija Karala,
Rebecca Groom, E. R. Waite & H. M. Hale (vectorized by T. Michael
Keesey), Ghedoghedo (vectorized by T. Michael Keesey), T. Michael
Keesey, Michael B. H. (vectorized by T. Michael Keesey), Becky Barnes,
Manabu Sakamoto, Maxime Dahirel, Steven Traver, Notafly (vectorized by
T. Michael Keesey), Mali’o Kodis, image from the “Proceedings of the
Zoological Society of London”, T. Michael Keesey (vectorization) and
Larry Loos (photography), Tracy A. Heath, Matt Martyniuk, Mo Hassan, Tim
Bertelink (modified by T. Michael Keesey), NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Michael Scroggie, Michelle Site, Cathy, Gabriela
Palomo-Munoz, DFoidl (vectorized by T. Michael Keesey), Marcos
Pérez-Losada, Jens T. Høeg & Keith A. Crandall, Felix Vaux, Mali’o
Kodis, photograph by John Slapcinsky, Lukasiniho, Smokeybjb, Qiang Ou,
Sharon Wegner-Larsen, xgirouxb, Mali’o Kodis, drawing by Manvir Singh,
Harold N Eyster, Michael P. Taylor, Ville-Veikko Sinkkonen, FunkMonk,
Pranav Iyer (grey ideas), Frank Förster, Hans Hillewaert (vectorized by
T. Michael Keesey), Ingo Braasch, Andreas Hejnol, Arthur S. Brum, T.
Tischler, T. Michael Keesey (after Joseph Wolf), Michele M Tobias from
an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Young and
Zhao (1972:figure 4), modified by Michael P. Taylor, Roberto Díaz
Sibaja, Walter Vladimir, Michael Day, Mali’o Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Inessa Voet, Martien
Brand (original photo), Renato Santos (vector silhouette), L. Shyamal,
Jonathan Wells, Paul O. Lewis, Noah Schlottman, Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Jim Bendon (photography) and T. Michael Keesey (vectorization),
David Orr, Nicolas Mongiardino Koch, Kai R. Caspar, Melissa Broussard,
Mark Witton, Roderic Page and Lois Page, Margret Flinsch, vectorized by
Zimices, Sarah Werning, V. Deepak, Matus Valach, Andrew A. Farke, T.
Michael Keesey (after Monika Betley), Tess Linden, , Mali’o Kodis,
photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Robert Gay,
Alexander Schmidt-Lebuhn, M Kolmann, Sean McCann, Mathilde Cordellier,
Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Karkemish
(vectorized by T. Michael Keesey), Kimberly Haddrell, S.Martini, Lisa M.
“Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Original photo by Andrew Murray, vectorized by Roberto
Díaz Sibaja, Greg Schechter (original photo), Renato Santos (vector
silhouette), Jaime Headden (vectorized by T. Michael Keesey), Lukas
Panzarin (vectorized by T. Michael Keesey), Brian Gratwicke (photo) and
T. Michael Keesey (vectorization), Jack Mayer Wood, Collin Gross, Ray
Simpson (vectorized by T. Michael Keesey), Milton Tan, Christine Axon,
Mariana Ruiz Villarreal, Noah Schlottman, photo by Casey Dunn, Michele
Tobias, T. Michael Keesey (after Masteraah), Nobu Tamura, vectorized by
Zimices, Original drawing by Antonov, vectorized by Roberto Díaz Sibaja,
Yan Wong from drawing by T. F. Zimmermann, George Edward Lodge
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by “Wildcat
Dunny” (<http://www.flickr.com/people/wildcat_dunny/>), Griensteidl and
T. Michael Keesey, Kent Sorgon, Chris A. Hamilton, Yan Wong from
wikipedia drawing (PD: Pearson Scott Foresman), Rafael Maia, Ben
Liebeskind, Rene Martin, Leon P. A. M. Claessens, Patrick M. O’Connor,
David M. Unwin, Robbie N. Cada (vectorized by T. Michael Keesey), Ernst
Haeckel (vectorized by T. Michael Keesey), Fernando Carezzano, Anthony
Caravaggi, Kailah Thorn & Mark Hutchinson, Alexandre Vong, Neil Kelley,
Nobu Tamura (modified by T. Michael Keesey), Nobu Tamura, Pearson Scott
Foresman (vectorized by T. Michael Keesey), Enoch Joseph Wetsy (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Stanton F. Fink (vectorized by T. Michael Keesey), E. Lear, 1819
(vectorization by Yan Wong), Noah Schlottman, photo by Antonio Guillén,
Matt Dempsey, Alex Slavenko, Mathieu Basille, Emily Jane McTavish, from
Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches,
Brad McFeeters (vectorized by T. Michael Keesey), Claus Rebler, T.
Michael Keesey and Tanetahi, James R. Spotila and Ray Chatterji, T.
Michael Keesey (photo by Bc999 \[Black crow\]), Kamil S. Jaron, Ricardo
Araújo, Mathew Wedel, Scott Hartman, modified by T. Michael Keesey,
Julia B McHugh, Frank Förster (based on a picture by Jerry Kirkhart;
modified by T. Michael Keesey), Andrew A. Farke, modified from original
by Robert Bruce Horsfall, from Scott 1912, A. H. Baldwin (vectorized by
T. Michael Keesey), Noah Schlottman, photo by Martin V. Sørensen,
Florian Pfaff, Arthur Weasley (vectorized by T. Michael Keesey), Zimices
/ Julián Bayona, AnAgnosticGod (vectorized by T. Michael Keesey),
kreidefossilien.de, Conty (vectorized by T. Michael Keesey), Philippe
Janvier (vectorized by T. Michael Keesey), CNZdenek, Meyers
Konversations-Lexikon 1897 (vectorized: Yan Wong), Jessica Anne Miller,
Smokeybjb, vectorized by Zimices, Mali’o Kodis, image from Higgins and
Kristensen, 1986, wsnaccad, Aline M. Ghilardi, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Katie S. Collins, E. D. Cope (modified by T. Michael Keesey,
Michael P. Taylor & Matthew J. Wedel), Scott D. Sampson, Mark A. Loewen,
Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith,
Alan L. Titus, Adrian Reich, Terpsichores, NASA, Mykle Hoban, Dmitry
Bogdanov, Renato Santos, Dianne Bray / Museum Victoria (vectorized by T.
Michael Keesey), John Curtis (vectorized by T. Michael Keesey), H. F. O.
March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J.
Wedel), Frank Förster (based on a picture by Hans Hillewaert), Cristian
Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Sam Droege (photo) and T. Michael Keesey
(vectorization), Charles Doolittle Walcott (vectorized by T. Michael
Keesey), Tyler Greenfield, Caleb Brown, Joedison Rocha, T. Michael
Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend &
Miguel Vences), Emily Jane McTavish, Benjamint444, Falconaumanni and T.
Michael Keesey, Jerry Oldenettel (vectorized by T. Michael Keesey), C.
Abraczinskas, Martin R. Smith, after Skovsted et al 2015, Noah
Schlottman, photo from National Science Foundation - Turbellarian
Taxonomic Database, Danielle Alba, Nicholas J. Czaplewski, vectorized by
Zimices, Abraão B. Leite, T. Michael Keesey (after Tillyard), Felix Vaux
and Steven A. Trewick, Sergio A. Muñoz-Gómez, Richard Parker (vectorized
by T. Michael Keesey), Yusan Yang, Oscar Sanisidro, Gustav Mützel,
Eduard Solà (vectorized by T. Michael Keesey), DW Bapst (modified from
Bates et al., 2005), Yan Wong from illustration by Charles Orbigny,
Christopher Watson (photo) and T. Michael Keesey (vectorization), Gopal
Murali, Birgit Lang; based on a drawing by C.L. Koch, Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Espen Horn (model; vectorized by T. Michael Keesey from a photo by H.
Zell), Jimmy Bernot, Raven Amos, Auckland Museum and T. Michael Keesey,
Matt Wilkins, Dave Angelini, Sherman Foote Denton (illustration, 1897)
and Timothy J. Bartley (silhouette)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     85.044298 |    456.265746 | Emily Willoughby                                                                                                                                                                     |
|   2 |    710.779548 |     70.181744 | Chloé Schmidt                                                                                                                                                                        |
|   3 |    960.309264 |    216.757279 | Beth Reinke                                                                                                                                                                          |
|   4 |    201.415882 |    206.359445 | Ferran Sayol                                                                                                                                                                         |
|   5 |    457.298149 |    665.299408 | Cesar Julian                                                                                                                                                                         |
|   6 |    355.061176 |    358.584571 | Scott Reid                                                                                                                                                                           |
|   7 |    650.267942 |    620.675680 | Tauana J. Cunha                                                                                                                                                                      |
|   8 |    530.541285 |    417.742902 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
|   9 |    900.145359 |    567.289059 | Martin R. Smith                                                                                                                                                                      |
|  10 |    502.213941 |    508.794728 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                                          |
|  11 |    508.267691 |    144.354197 | Matt Crook                                                                                                                                                                           |
|  12 |    280.477688 |    567.487026 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
|  13 |    691.822105 |    160.960609 | Trond R. Oskars                                                                                                                                                                      |
|  14 |    640.061490 |    326.092726 | Dean Schnabel                                                                                                                                                                        |
|  15 |    116.042556 |    547.881595 | Matt Crook                                                                                                                                                                           |
|  16 |    448.390086 |    741.538373 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
|  17 |    198.031093 |    718.861352 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                               |
|  18 |    858.682067 |    118.577195 | Ferran Sayol                                                                                                                                                                         |
|  19 |    525.782013 |    297.908752 | Chris huh                                                                                                                                                                            |
|  20 |    683.838010 |    418.154706 | Yan Wong                                                                                                                                                                             |
|  21 |    104.165679 |     66.616997 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
|  22 |    935.540088 |    177.860542 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  23 |    410.961079 |    447.348395 | Matt Crook                                                                                                                                                                           |
|  24 |    282.422709 |    101.310664 | Matthew E. Clapham                                                                                                                                                                   |
|  25 |    420.145274 |     99.555612 | Xavier Giroux-Bougard                                                                                                                                                                |
|  26 |    841.160693 |    305.831275 | Joanna Wolfe                                                                                                                                                                         |
|  27 |    239.610160 |    460.638306 | Zimices                                                                                                                                                                              |
|  28 |    496.350143 |    603.573828 | Carlos Cano-Barbacil                                                                                                                                                                 |
|  29 |    992.895093 |    573.035638 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
|  30 |    188.286447 |    347.449741 | Birgit Lang                                                                                                                                                                          |
|  31 |    734.401741 |    367.530728 | Scott Hartman                                                                                                                                                                        |
|  32 |    300.363871 |    731.381977 | Matt Crook                                                                                                                                                                           |
|  33 |    611.441798 |     63.605101 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                         |
|  34 |    105.188140 |    400.993357 | Christoph Schomburg                                                                                                                                                                  |
|  35 |    126.699744 |    261.347969 | Smokeybjb (modified by Mike Keesey)                                                                                                                                                  |
|  36 |    799.200840 |    677.616847 | Dean Schnabel                                                                                                                                                                        |
|  37 |    356.287355 |    184.006866 | Tasman Dixon                                                                                                                                                                         |
|  38 |    180.069453 |    119.355574 | NA                                                                                                                                                                                   |
|  39 |    841.889185 |    569.833016 | Jiekun He                                                                                                                                                                            |
|  40 |     36.626676 |    637.386721 | Margot Michaud                                                                                                                                                                       |
|  41 |    685.720659 |    697.165778 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  42 |    567.675923 |    707.390145 | Marie Russell                                                                                                                                                                        |
|  43 |    357.112471 |    262.702841 | Chris Jennings (Risiatto)                                                                                                                                                            |
|  44 |    715.257376 |    518.157073 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                     |
|  45 |    205.600901 |    551.665476 | Gareth Monger                                                                                                                                                                        |
|  46 |    191.267190 |    375.874522 | Zimices                                                                                                                                                                              |
|  47 |    623.887986 |    227.974484 | Chase Brownstein                                                                                                                                                                     |
|  48 |    303.700404 |    410.380692 | Chloé Schmidt                                                                                                                                                                        |
|  49 |     70.211517 |    169.814262 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
|  50 |    353.406322 |    555.351729 | Birgit Lang                                                                                                                                                                          |
|  51 |    939.652503 |    284.164948 | Jagged Fang Designs                                                                                                                                                                  |
|  52 |    148.556530 |    638.924984 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  53 |    328.561513 |    646.426096 | Servien (vectorized by T. Michael Keesey)                                                                                                                                            |
|  54 |    697.548068 |    758.301651 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
|  55 |    404.852175 |     42.228171 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  56 |     93.102844 |    728.182013 | Joanna Wolfe                                                                                                                                                                         |
|  57 |    612.679463 |    388.381752 | Gareth Monger                                                                                                                                                                        |
|  58 |    429.740894 |    229.374574 | Chris Hay                                                                                                                                                                            |
|  59 |    762.329804 |    225.604469 | Mattia Menchetti                                                                                                                                                                     |
|  60 |    736.877908 |    275.742305 | Scott Hartman                                                                                                                                                                        |
|  61 |    973.542643 |    692.664946 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
|  62 |     85.190588 |    340.797530 | terngirl                                                                                                                                                                             |
|  63 |    179.287248 |    293.148351 | Margot Michaud                                                                                                                                                                       |
|  64 |    759.342756 |     16.715974 | Margot Michaud                                                                                                                                                                       |
|  65 |    918.567671 |     18.980169 | Steven Coombs                                                                                                                                                                        |
|  66 |    530.786290 |     56.927080 | NA                                                                                                                                                                                   |
|  67 |    268.186141 |    287.377888 | Yan Wong                                                                                                                                                                             |
|  68 |    784.193621 |    446.323864 | NA                                                                                                                                                                                   |
|  69 |    842.483239 |    503.869775 | (after Spotila 2004)                                                                                                                                                                 |
|  70 |    489.128544 |    364.095232 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  71 |    804.704789 |    759.544477 | T. Michael Keesey (after Mauricio Antón)                                                                                                                                             |
|  72 |    392.535572 |     19.275032 | Jaime Headden                                                                                                                                                                        |
|  73 |    403.819694 |    564.806080 | Yan Wong (vectorization) from 1873 illustration                                                                                                                                      |
|  74 |    616.146486 |    468.899125 | Beth Reinke                                                                                                                                                                          |
|  75 |    579.511839 |    550.038974 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
|  76 |    395.747549 |    151.703526 | Iain Reid                                                                                                                                                                            |
|  77 |    107.484222 |    180.711320 | Matt Crook                                                                                                                                                                           |
|  78 |    327.936888 |    472.667177 | Birgit Lang                                                                                                                                                                          |
|  79 |    360.490458 |    310.665379 | Gareth Monger                                                                                                                                                                        |
|  80 |    627.693570 |    180.682397 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  81 |     51.450901 |    421.326904 | Ghedoghedo                                                                                                                                                                           |
|  82 |    237.165658 |    723.358296 | Matt Crook                                                                                                                                                                           |
|  83 |    850.175470 |    780.130251 | Maija Karala                                                                                                                                                                         |
|  84 |    243.310373 |     19.753504 | Rebecca Groom                                                                                                                                                                        |
|  85 |    320.865577 |    217.363295 | Rebecca Groom                                                                                                                                                                        |
|  86 |     84.941704 |    605.166846 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                           |
|  87 |     48.406106 |    381.038445 | Margot Michaud                                                                                                                                                                       |
|  88 |    999.263467 |     95.726565 | NA                                                                                                                                                                                   |
|  89 |    538.095920 |    756.216430 | Chris huh                                                                                                                                                                            |
|  90 |    961.195335 |    786.242349 | Scott Reid                                                                                                                                                                           |
|  91 |    148.860244 |    765.589057 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
|  92 |     65.888024 |    621.673806 | T. Michael Keesey                                                                                                                                                                    |
|  93 |    185.454744 |    658.584921 | Matt Crook                                                                                                                                                                           |
|  94 |    980.206773 |    362.359286 | Chris huh                                                                                                                                                                            |
|  95 |    851.599075 |     32.219093 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                      |
|  96 |    127.962087 |    203.247934 | Maija Karala                                                                                                                                                                         |
|  97 |    808.190247 |    437.804827 | Becky Barnes                                                                                                                                                                         |
|  98 |    154.299449 |    479.633533 | Manabu Sakamoto                                                                                                                                                                      |
|  99 |    704.212688 |    293.463395 | Tasman Dixon                                                                                                                                                                         |
| 100 |    655.909391 |    270.188995 | Zimices                                                                                                                                                                              |
| 101 |    947.227751 |    717.411973 | Maxime Dahirel                                                                                                                                                                       |
| 102 |    128.684886 |    506.432197 | Chris huh                                                                                                                                                                            |
| 103 |    220.049992 |     42.282652 | Steven Traver                                                                                                                                                                        |
| 104 |     31.150039 |    165.387199 | Gareth Monger                                                                                                                                                                        |
| 105 |    545.590693 |    230.857023 | Steven Traver                                                                                                                                                                        |
| 106 |   1008.761003 |    496.747702 | Zimices                                                                                                                                                                              |
| 107 |    856.831390 |    357.167585 | Margot Michaud                                                                                                                                                                       |
| 108 |     35.882607 |    502.401647 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                            |
| 109 |     35.041328 |    711.594236 | Margot Michaud                                                                                                                                                                       |
| 110 |    880.670439 |    782.260139 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                                       |
| 111 |    981.387482 |    292.481947 | Birgit Lang                                                                                                                                                                          |
| 112 |     12.323383 |    498.515943 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                                       |
| 113 |    758.961158 |    594.216821 | Ferran Sayol                                                                                                                                                                         |
| 114 |    521.197235 |    253.559604 | Tracy A. Heath                                                                                                                                                                       |
| 115 |    562.112814 |    635.985571 | Margot Michaud                                                                                                                                                                       |
| 116 |    762.174210 |    162.394766 | Matt Martyniuk                                                                                                                                                                       |
| 117 |    384.500519 |    304.232586 | Mo Hassan                                                                                                                                                                            |
| 118 |     98.045395 |    295.934571 | Zimices                                                                                                                                                                              |
| 119 |     51.971067 |    364.405241 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 120 |    909.875626 |    377.363832 | Matt Crook                                                                                                                                                                           |
| 121 |    224.029301 |    305.170318 | Dean Schnabel                                                                                                                                                                        |
| 122 |    374.272267 |     70.632717 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                        |
| 123 |    569.510185 |    792.581987 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                                |
| 124 |    180.990483 |     18.308427 | Zimices                                                                                                                                                                              |
| 125 |    498.996068 |    229.964005 | Michael Scroggie                                                                                                                                                                     |
| 126 |    443.399357 |    518.561382 | Tracy A. Heath                                                                                                                                                                       |
| 127 |    820.349779 |    562.656282 | Zimices                                                                                                                                                                              |
| 128 |    148.772854 |    439.113143 | Michelle Site                                                                                                                                                                        |
| 129 |    261.720150 |    424.949368 | Cathy                                                                                                                                                                                |
| 130 |    340.552451 |    695.681695 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 131 |    572.599340 |    519.306762 | Jagged Fang Designs                                                                                                                                                                  |
| 132 |    538.568364 |    330.738753 | Michael Scroggie                                                                                                                                                                     |
| 133 |     62.239039 |     79.085362 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                                             |
| 134 |    495.939239 |    568.644275 | Margot Michaud                                                                                                                                                                       |
| 135 |    464.160528 |    119.328580 | Steven Traver                                                                                                                                                                        |
| 136 |    190.296673 |    610.146628 | Gareth Monger                                                                                                                                                                        |
| 137 |    144.985573 |    215.104271 | Matt Crook                                                                                                                                                                           |
| 138 |    438.131711 |    172.765154 | Margot Michaud                                                                                                                                                                       |
| 139 |   1002.444109 |    453.117786 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                                |
| 140 |    202.663863 |    480.425441 | Felix Vaux                                                                                                                                                                           |
| 141 |    372.536252 |    715.453037 | Ferran Sayol                                                                                                                                                                         |
| 142 |    778.758865 |     50.759548 | Tasman Dixon                                                                                                                                                                         |
| 143 |    525.727303 |    190.328204 | Michael Scroggie                                                                                                                                                                     |
| 144 |    301.204871 |    316.693133 | Chris Jennings (Risiatto)                                                                                                                                                            |
| 145 |     28.100793 |    122.661939 | Matt Crook                                                                                                                                                                           |
| 146 |     21.494952 |    566.620245 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                          |
| 147 |    593.661624 |    750.731503 | Lukasiniho                                                                                                                                                                           |
| 148 |    588.461604 |     82.892570 | Zimices                                                                                                                                                                              |
| 149 |    579.667149 |    662.883841 | NA                                                                                                                                                                                   |
| 150 |    698.260652 |    225.088721 | Chris huh                                                                                                                                                                            |
| 151 |    411.772343 |    406.151590 | Smokeybjb                                                                                                                                                                            |
| 152 |    114.604964 |    360.131039 | Qiang Ou                                                                                                                                                                             |
| 153 |    479.205646 |    458.504320 | Smokeybjb                                                                                                                                                                            |
| 154 |    243.625559 |    571.436145 | Margot Michaud                                                                                                                                                                       |
| 155 |    681.122795 |    289.393175 | Matt Crook                                                                                                                                                                           |
| 156 |    547.156584 |    318.868081 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 157 |    345.070067 |    454.344354 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 158 |     67.145292 |    319.721368 | xgirouxb                                                                                                                                                                             |
| 159 |    759.087529 |    414.426616 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                                |
| 160 |   1002.405340 |    481.694084 | Gareth Monger                                                                                                                                                                        |
| 161 |    201.940344 |    429.271543 | Steven Traver                                                                                                                                                                        |
| 162 |     12.517609 |     98.369539 | Harold N Eyster                                                                                                                                                                      |
| 163 |    176.982878 |     40.925965 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 164 |    278.753183 |    354.433787 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 165 |    337.682043 |    492.309022 | Jagged Fang Designs                                                                                                                                                                  |
| 166 |    938.519160 |    237.018009 | Michael P. Taylor                                                                                                                                                                    |
| 167 |    760.673934 |    728.748516 | Jagged Fang Designs                                                                                                                                                                  |
| 168 |    112.389970 |    498.724888 | Matt Martyniuk                                                                                                                                                                       |
| 169 |    966.814114 |    123.270419 | Gareth Monger                                                                                                                                                                        |
| 170 |    759.927298 |    380.812555 | Cesar Julian                                                                                                                                                                         |
| 171 |    676.670317 |     25.019282 | NA                                                                                                                                                                                   |
| 172 |    962.878880 |    577.789422 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 173 |    755.899445 |    200.927630 | Ferran Sayol                                                                                                                                                                         |
| 174 |    758.638500 |    248.174856 | FunkMonk                                                                                                                                                                             |
| 175 |    596.599838 |    774.986710 | T. Michael Keesey                                                                                                                                                                    |
| 176 |    375.916013 |    597.366506 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 177 |    525.945993 |     26.069332 | Frank Förster                                                                                                                                                                        |
| 178 |    296.575888 |    667.987811 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 179 |     21.918036 |     62.083876 | Ingo Braasch                                                                                                                                                                         |
| 180 |    529.200186 |      8.383504 | Emily Willoughby                                                                                                                                                                     |
| 181 |     49.330625 |    500.127698 | Andreas Hejnol                                                                                                                                                                       |
| 182 |    191.553342 |    413.326173 | NA                                                                                                                                                                                   |
| 183 |    199.429204 |     12.074649 | Lukasiniho                                                                                                                                                                           |
| 184 |    488.291335 |     93.634166 | Scott Hartman                                                                                                                                                                        |
| 185 |    184.801041 |    478.547594 | Arthur S. Brum                                                                                                                                                                       |
| 186 |    711.395721 |    116.599840 | T. Tischler                                                                                                                                                                          |
| 187 |    111.731417 |    280.792264 | Chris huh                                                                                                                                                                            |
| 188 |    361.641358 |    153.297401 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                                |
| 189 |    695.129353 |    239.870200 | Matt Crook                                                                                                                                                                           |
| 190 |     91.531196 |    491.557327 | xgirouxb                                                                                                                                                                             |
| 191 |    345.633953 |    757.660269 | Margot Michaud                                                                                                                                                                       |
| 192 |    131.257330 |    150.057554 | Zimices                                                                                                                                                                              |
| 193 |    270.008209 |    193.322987 | Ferran Sayol                                                                                                                                                                         |
| 194 |     29.529429 |    253.524851 | NA                                                                                                                                                                                   |
| 195 |    353.360135 |    123.554597 | Gareth Monger                                                                                                                                                                        |
| 196 |    653.081749 |    521.663723 | T. Michael Keesey                                                                                                                                                                    |
| 197 |    591.080397 |    173.595204 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                                           |
| 198 |    830.224209 |    611.342351 | xgirouxb                                                                                                                                                                             |
| 199 |    772.471487 |    790.019067 | Scott Hartman                                                                                                                                                                        |
| 200 |    508.576154 |    642.985377 | Scott Hartman                                                                                                                                                                        |
| 201 |    443.762381 |    276.125054 | Margot Michaud                                                                                                                                                                       |
| 202 |    643.227687 |     85.174733 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 203 |    738.936745 |    107.517446 | T. Michael Keesey                                                                                                                                                                    |
| 204 |    506.875094 |    560.560831 | Chris huh                                                                                                                                                                            |
| 205 |     18.863914 |    359.586339 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                        |
| 206 |    467.760058 |    637.338963 | Zimices                                                                                                                                                                              |
| 207 |    860.006594 |    201.853302 | Margot Michaud                                                                                                                                                                       |
| 208 |    227.435071 |    383.344666 | Steven Traver                                                                                                                                                                        |
| 209 |    409.601618 |    650.390050 | Steven Traver                                                                                                                                                                        |
| 210 |    928.964227 |    780.806823 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 211 |    114.906102 |    162.618267 | Matt Crook                                                                                                                                                                           |
| 212 |    314.478133 |    496.739595 | Zimices                                                                                                                                                                              |
| 213 |    603.930045 |    440.196686 | Maija Karala                                                                                                                                                                         |
| 214 |    943.810504 |     92.452412 | Margot Michaud                                                                                                                                                                       |
| 215 |    549.004623 |    260.384664 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 216 |    302.035719 |    209.913670 | Walter Vladimir                                                                                                                                                                      |
| 217 |     62.105453 |     37.784504 | Michael Day                                                                                                                                                                          |
| 218 |    228.398451 |    269.080351 | Felix Vaux                                                                                                                                                                           |
| 219 |    353.581594 |    703.064251 | Jagged Fang Designs                                                                                                                                                                  |
| 220 |    863.084442 |    789.335459 | Matthew E. Clapham                                                                                                                                                                   |
| 221 |    509.041565 |    770.595827 | Dean Schnabel                                                                                                                                                                        |
| 222 |    761.471598 |    475.780965 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                                     |
| 223 |    776.347171 |    405.927085 | Inessa Voet                                                                                                                                                                          |
| 224 |    131.278582 |    122.370013 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 225 |     57.227809 |    121.384899 | Matt Crook                                                                                                                                                                           |
| 226 |    740.259380 |    602.478317 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
| 227 |    236.868042 |    528.914760 | Steven Traver                                                                                                                                                                        |
| 228 |    219.726143 |    418.086813 | L. Shyamal                                                                                                                                                                           |
| 229 |    775.617380 |    492.034249 | Jonathan Wells                                                                                                                                                                       |
| 230 |    351.477308 |    784.378744 | Zimices                                                                                                                                                                              |
| 231 |    954.551849 |    495.471421 | Paul O. Lewis                                                                                                                                                                        |
| 232 |    494.334751 |    437.408955 | Chris huh                                                                                                                                                                            |
| 233 |    384.279036 |    322.678745 | Noah Schlottman                                                                                                                                                                      |
| 234 |    404.639195 |    761.064356 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 235 |    929.495759 |    755.924450 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 236 |     32.575271 |    475.974864 | David Orr                                                                                                                                                                            |
| 237 |    500.520522 |    397.604041 | Nicolas Mongiardino Koch                                                                                                                                                             |
| 238 |     18.185085 |    401.170424 | Birgit Lang                                                                                                                                                                          |
| 239 |    348.605255 |    312.352692 | Rebecca Groom                                                                                                                                                                        |
| 240 |    435.558840 |    627.093453 | Kai R. Caspar                                                                                                                                                                        |
| 241 |     95.348593 |    237.439806 | Scott Hartman                                                                                                                                                                        |
| 242 |    970.306257 |    467.947004 | Matt Crook                                                                                                                                                                           |
| 243 |    820.057273 |    548.589245 | Melissa Broussard                                                                                                                                                                    |
| 244 |    407.735215 |    201.959796 | Zimices                                                                                                                                                                              |
| 245 |    283.270062 |    691.258242 | Mark Witton                                                                                                                                                                          |
| 246 |    398.422052 |    179.383334 | Tasman Dixon                                                                                                                                                                         |
| 247 |    968.302858 |    613.256740 | T. Michael Keesey                                                                                                                                                                    |
| 248 |    148.830083 |    748.054775 | Matt Crook                                                                                                                                                                           |
| 249 |    480.615358 |    384.132113 | Beth Reinke                                                                                                                                                                          |
| 250 |    298.473057 |    386.498209 | Michelle Site                                                                                                                                                                        |
| 251 |    780.750494 |    378.147569 | Michael Day                                                                                                                                                                          |
| 252 |    898.719401 |    360.483501 | Roderic Page and Lois Page                                                                                                                                                           |
| 253 |     39.208440 |     51.378649 | Ferran Sayol                                                                                                                                                                         |
| 254 |    610.526864 |    792.850238 | Michelle Site                                                                                                                                                                        |
| 255 |    356.468370 |    581.171359 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 256 |     33.432559 |    375.293445 | Cathy                                                                                                                                                                                |
| 257 |    789.130863 |    420.896336 | NA                                                                                                                                                                                   |
| 258 |    727.152996 |    249.992070 | Jagged Fang Designs                                                                                                                                                                  |
| 259 |    649.927310 |     62.451491 | Tasman Dixon                                                                                                                                                                         |
| 260 |    378.710522 |    778.172914 | Margot Michaud                                                                                                                                                                       |
| 261 |    439.397261 |    265.395116 | Margret Flinsch, vectorized by Zimices                                                                                                                                               |
| 262 |     17.540396 |    330.630886 | NA                                                                                                                                                                                   |
| 263 |    687.995111 |    583.427140 | Michael Scroggie                                                                                                                                                                     |
| 264 |    229.958011 |    545.324175 | Margot Michaud                                                                                                                                                                       |
| 265 |    704.147762 |    454.562380 | Maxime Dahirel                                                                                                                                                                       |
| 266 |    382.195052 |    758.665620 | Margot Michaud                                                                                                                                                                       |
| 267 |    330.274410 |    592.599197 | NA                                                                                                                                                                                   |
| 268 |    869.585115 |    230.066682 | Michael Scroggie                                                                                                                                                                     |
| 269 |    589.269354 |    594.412368 | Sarah Werning                                                                                                                                                                        |
| 270 |    819.672627 |    364.639126 | Matt Martyniuk                                                                                                                                                                       |
| 271 |    151.452633 |    709.101801 | Matt Crook                                                                                                                                                                           |
| 272 |    526.189261 |    785.042858 | V. Deepak                                                                                                                                                                            |
| 273 |    521.499819 |    388.969337 | Matus Valach                                                                                                                                                                         |
| 274 |     52.791491 |    282.268134 | Zimices                                                                                                                                                                              |
| 275 |    848.308374 |    748.816414 | Matt Crook                                                                                                                                                                           |
| 276 |    687.282999 |    381.496587 | Andrew A. Farke                                                                                                                                                                      |
| 277 |    316.217548 |    762.669851 | T. Michael Keesey (after Monika Betley)                                                                                                                                              |
| 278 |     13.985428 |    726.751076 | Gareth Monger                                                                                                                                                                        |
| 279 |    888.621477 |    225.477004 | Chris huh                                                                                                                                                                            |
| 280 |     42.621704 |    270.056652 | Tess Linden                                                                                                                                                                          |
| 281 |    786.144460 |    467.302868 |                                                                                                                                                                                      |
| 282 |    716.543356 |    341.518963 | Yan Wong                                                                                                                                                                             |
| 283 |     22.684019 |    295.565955 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                       |
| 284 |    723.502894 |    441.029878 | Robert Gay                                                                                                                                                                           |
| 285 |    550.978377 |    186.729456 | Christoph Schomburg                                                                                                                                                                  |
| 286 |    806.299540 |    313.890643 | Gareth Monger                                                                                                                                                                        |
| 287 |    119.655199 |    760.039168 | Zimices                                                                                                                                                                              |
| 288 |    990.186382 |    334.682213 | Jaime Headden                                                                                                                                                                        |
| 289 |    204.698612 |    631.910861 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 290 |    481.219179 |    131.525086 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 291 |    413.131003 |    498.670186 | M Kolmann                                                                                                                                                                            |
| 292 |     77.692563 |    275.441275 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 293 |    247.970562 |    298.565119 | Sean McCann                                                                                                                                                                          |
| 294 |    774.903525 |    617.471677 | Mathilde Cordellier                                                                                                                                                                  |
| 295 |    993.732666 |    413.976820 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 296 |    479.719039 |    220.602666 | Jagged Fang Designs                                                                                                                                                                  |
| 297 |    387.834850 |    630.847599 | Gareth Monger                                                                                                                                                                        |
| 298 |    637.703896 |    207.280783 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                                |
| 299 |    750.024419 |    321.677142 | Zimices                                                                                                                                                                              |
| 300 |    438.020906 |    551.984783 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                                          |
| 301 |    687.760828 |    729.218108 | Chris huh                                                                                                                                                                            |
| 302 |    271.378725 |    786.241593 | Kimberly Haddrell                                                                                                                                                                    |
| 303 |   1012.150628 |    666.385566 | Michelle Site                                                                                                                                                                        |
| 304 |    186.724095 |    533.630499 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 305 |    289.549180 |    788.915820 | Sarah Werning                                                                                                                                                                        |
| 306 |    708.728016 |    584.325010 | Matt Crook                                                                                                                                                                           |
| 307 |     27.438183 |     89.184598 | Matt Crook                                                                                                                                                                           |
| 308 |    717.291597 |    624.244505 | S.Martini                                                                                                                                                                            |
| 309 |    947.002745 |    504.236061 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                      |
| 310 |    518.261180 |    197.761651 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                                   |
| 311 |    802.405367 |    161.485942 | Margot Michaud                                                                                                                                                                       |
| 312 |    687.391208 |    597.915197 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                                   |
| 313 |    572.412957 |    335.523025 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                                      |
| 314 |    160.779522 |     52.520200 | Scott Hartman                                                                                                                                                                        |
| 315 |    350.256897 |    224.725158 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                                     |
| 316 |    715.184972 |    750.859181 | Gareth Monger                                                                                                                                                                        |
| 317 |    817.379407 |    237.463526 | Ferran Sayol                                                                                                                                                                         |
| 318 |   1008.618985 |    514.832292 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 319 |    956.035254 |    188.637831 | Tasman Dixon                                                                                                                                                                         |
| 320 |    555.177658 |    491.065520 | Jack Mayer Wood                                                                                                                                                                      |
| 321 |     29.477643 |    210.269373 | Jaime Headden                                                                                                                                                                        |
| 322 |    124.498144 |    587.397397 | Sarah Werning                                                                                                                                                                        |
| 323 |    327.135668 |    152.837713 | Ferran Sayol                                                                                                                                                                         |
| 324 |    117.458062 |    792.698586 | Collin Gross                                                                                                                                                                         |
| 325 |    590.200958 |    649.349410 | Steven Traver                                                                                                                                                                        |
| 326 |    401.738208 |    485.998269 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                        |
| 327 |    142.381208 |    334.524024 | xgirouxb                                                                                                                                                                             |
| 328 |     41.416764 |    288.778093 | Milton Tan                                                                                                                                                                           |
| 329 |    477.266850 |    791.496666 | Matt Crook                                                                                                                                                                           |
| 330 |    238.462248 |    645.718358 | Margot Michaud                                                                                                                                                                       |
| 331 |     20.716958 |    222.012255 | Zimices                                                                                                                                                                              |
| 332 |    357.313115 |    212.585754 | David Orr                                                                                                                                                                            |
| 333 |     36.890848 |    743.194226 | Margot Michaud                                                                                                                                                                       |
| 334 |    734.598524 |    698.203145 | Mathilde Cordellier                                                                                                                                                                  |
| 335 |    783.130520 |    346.689158 | Jagged Fang Designs                                                                                                                                                                  |
| 336 |   1003.266529 |    167.438894 | Christine Axon                                                                                                                                                                       |
| 337 |    376.918986 |    447.791280 | Michael Scroggie                                                                                                                                                                     |
| 338 |    946.723392 |    594.133456 | Mariana Ruiz Villarreal                                                                                                                                                              |
| 339 |    991.052109 |    768.317306 | Matt Crook                                                                                                                                                                           |
| 340 |    606.515427 |     98.152709 | Ferran Sayol                                                                                                                                                                         |
| 341 |    408.448902 |     70.514984 | Margot Michaud                                                                                                                                                                       |
| 342 |    243.091902 |    400.356261 | T. Michael Keesey                                                                                                                                                                    |
| 343 |   1001.897735 |    649.462183 | Emily Willoughby                                                                                                                                                                     |
| 344 |     86.497314 |    506.784545 | Margot Michaud                                                                                                                                                                       |
| 345 |    945.541699 |    458.110606 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 346 |     28.579986 |    143.209364 | Gareth Monger                                                                                                                                                                        |
| 347 |    783.939249 |    607.453135 | (after Spotila 2004)                                                                                                                                                                 |
| 348 |    792.133045 |    478.282561 | NA                                                                                                                                                                                   |
| 349 |    374.987255 |    671.362593 | Michele Tobias                                                                                                                                                                       |
| 350 |    441.706133 |    180.733938 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 351 |    341.596251 |    235.465377 | T. Michael Keesey (after Masteraah)                                                                                                                                                  |
| 352 |    499.023098 |    210.439338 | Kai R. Caspar                                                                                                                                                                        |
| 353 |    833.230041 |    164.512947 | Tasman Dixon                                                                                                                                                                         |
| 354 |    372.740173 |    162.525745 | Maija Karala                                                                                                                                                                         |
| 355 |    926.339031 |    342.298174 | Zimices                                                                                                                                                                              |
| 356 |    824.741726 |    189.141451 | Steven Traver                                                                                                                                                                        |
| 357 |    644.178502 |    342.742241 | Zimices                                                                                                                                                                              |
| 358 |    962.949448 |    262.342842 | Michael Scroggie                                                                                                                                                                     |
| 359 |    572.299164 |     74.829015 | Jagged Fang Designs                                                                                                                                                                  |
| 360 |    837.796272 |    734.927155 | Zimices                                                                                                                                                                              |
| 361 |    586.498789 |    493.396704 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 362 |    393.786310 |    747.956660 | Jagged Fang Designs                                                                                                                                                                  |
| 363 |   1019.482823 |    251.067973 | NA                                                                                                                                                                                   |
| 364 |    266.348249 |    163.966728 | Matt Crook                                                                                                                                                                           |
| 365 |    998.979279 |    388.590807 | Margot Michaud                                                                                                                                                                       |
| 366 |    151.301604 |    250.279169 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                                       |
| 367 |    248.779917 |    620.677491 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                                            |
| 368 |    576.278823 |     29.708574 | Mo Hassan                                                                                                                                                                            |
| 369 |    849.181009 |    711.942385 | Ferran Sayol                                                                                                                                                                         |
| 370 |    445.368392 |    456.987793 | S.Martini                                                                                                                                                                            |
| 371 |    214.803674 |     11.824537 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                                |
| 372 |    634.287269 |    191.486758 | S.Martini                                                                                                                                                                            |
| 373 |    543.835976 |    252.079241 | NA                                                                                                                                                                                   |
| 374 |    589.181622 |    680.426703 | Christoph Schomburg                                                                                                                                                                  |
| 375 |    325.170995 |    453.306518 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                                          |
| 376 |     27.661521 |    104.969684 | Zimices                                                                                                                                                                              |
| 377 |    642.021305 |    540.957502 | NA                                                                                                                                                                                   |
| 378 |    970.852783 |    651.916450 | T. Michael Keesey                                                                                                                                                                    |
| 379 |     75.892514 |    598.013836 | Scott Hartman                                                                                                                                                                        |
| 380 |    943.289026 |    139.371641 | Beth Reinke                                                                                                                                                                          |
| 381 |    248.519511 |    606.049047 | Margot Michaud                                                                                                                                                                       |
| 382 |    999.627938 |    147.887431 | T. Michael Keesey                                                                                                                                                                    |
| 383 |     83.921965 |     79.099030 | Scott Hartman                                                                                                                                                                        |
| 384 |     54.406963 |    568.933966 | Mattia Menchetti                                                                                                                                                                     |
| 385 |    667.943373 |     22.143802 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 386 |    147.251574 |    644.820472 | Collin Gross                                                                                                                                                                         |
| 387 |     11.795145 |    380.793345 | T. Michael Keesey                                                                                                                                                                    |
| 388 |    418.951095 |    790.769207 | Margot Michaud                                                                                                                                                                       |
| 389 |    888.814141 |    476.733374 | Scott Hartman                                                                                                                                                                        |
| 390 |    404.808993 |     60.166418 | Maxime Dahirel                                                                                                                                                                       |
| 391 |    267.378757 |    358.773273 | Emily Willoughby                                                                                                                                                                     |
| 392 |    209.101895 |    740.832510 | Jagged Fang Designs                                                                                                                                                                  |
| 393 |    214.500389 |    647.922526 | Matt Martyniuk                                                                                                                                                                       |
| 394 |    998.411905 |    191.967485 | Kent Sorgon                                                                                                                                                                          |
| 395 |    208.364620 |    283.382000 | Collin Gross                                                                                                                                                                         |
| 396 |    212.235883 |    715.860272 | Chris A. Hamilton                                                                                                                                                                    |
| 397 |    175.145054 |      7.275396 | Lukasiniho                                                                                                                                                                           |
| 398 |    778.807762 |    153.445870 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                         |
| 399 |    100.863069 |    419.092744 | Scott Hartman                                                                                                                                                                        |
| 400 |     43.022862 |    217.157735 | NA                                                                                                                                                                                   |
| 401 |    241.540372 |    319.057525 | Zimices                                                                                                                                                                              |
| 402 |    226.918018 |    596.319695 | Rafael Maia                                                                                                                                                                          |
| 403 |    294.782691 |    361.833555 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 404 |    859.592671 |    680.279626 | Joanna Wolfe                                                                                                                                                                         |
| 405 |    940.655559 |    694.830160 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 406 |    774.360694 |    430.756983 | Andrew A. Farke                                                                                                                                                                      |
| 407 |     22.936018 |    536.874682 | Gareth Monger                                                                                                                                                                        |
| 408 |    412.564538 |    324.451081 | FunkMonk                                                                                                                                                                             |
| 409 |    949.434921 |    348.104665 | Ben Liebeskind                                                                                                                                                                       |
| 410 |    978.028694 |    600.255184 | Kai R. Caspar                                                                                                                                                                        |
| 411 |    481.451375 |    429.540430 | Jagged Fang Designs                                                                                                                                                                  |
| 412 |    924.610319 |    724.988410 | Michelle Site                                                                                                                                                                        |
| 413 |    288.702288 |    214.519863 | Christine Axon                                                                                                                                                                       |
| 414 |     37.567943 |    409.968382 | NA                                                                                                                                                                                   |
| 415 |    631.637388 |    678.618218 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 416 |    582.545893 |    480.420831 | Margot Michaud                                                                                                                                                                       |
| 417 |    431.229954 |    590.536493 | Dean Schnabel                                                                                                                                                                        |
| 418 |    332.663602 |    683.929465 | Matt Crook                                                                                                                                                                           |
| 419 |    187.107679 |    423.844981 | Rene Martin                                                                                                                                                                          |
| 420 |    179.926577 |    603.722407 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                                         |
| 421 |    746.063174 |    689.080657 | Michael Scroggie                                                                                                                                                                     |
| 422 |    381.577010 |    427.087226 | Zimices                                                                                                                                                                              |
| 423 |    103.743646 |    228.043424 | Margot Michaud                                                                                                                                                                       |
| 424 |   1014.076204 |    319.138506 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 425 |    524.723996 |    687.628585 | Birgit Lang                                                                                                                                                                          |
| 426 |    653.146129 |    696.013064 | Christoph Schomburg                                                                                                                                                                  |
| 427 |    175.157631 |    240.322942 | Matt Crook                                                                                                                                                                           |
| 428 |    117.696047 |     13.604343 | Tasman Dixon                                                                                                                                                                         |
| 429 |    897.624022 |    311.115903 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 430 |      6.629962 |    784.123213 | Ferran Sayol                                                                                                                                                                         |
| 431 |     99.222629 |    128.440803 | Jagged Fang Designs                                                                                                                                                                  |
| 432 |     50.058222 |    596.938948 | Joanna Wolfe                                                                                                                                                                         |
| 433 |    811.373745 |    464.944016 | Margot Michaud                                                                                                                                                                       |
| 434 |    844.129573 |    385.106129 | Margot Michaud                                                                                                                                                                       |
| 435 |    349.497753 |    669.286601 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 436 |    462.323466 |     64.841006 | Steven Traver                                                                                                                                                                        |
| 437 |   1007.258667 |    733.975896 | Jonathan Wells                                                                                                                                                                       |
| 438 |    944.056388 |    541.302500 | Fernando Carezzano                                                                                                                                                                   |
| 439 |    972.865678 |    584.435650 | Margot Michaud                                                                                                                                                                       |
| 440 |    386.437731 |    128.382313 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 441 |    262.753439 |    674.916490 | Anthony Caravaggi                                                                                                                                                                    |
| 442 |    389.435322 |    502.294153 | Yan Wong                                                                                                                                                                             |
| 443 |    428.178296 |    490.458580 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 444 |    982.056795 |    241.134260 | Rebecca Groom                                                                                                                                                                        |
| 445 |    343.695773 |    154.335426 | Alexandre Vong                                                                                                                                                                       |
| 446 |    324.609718 |    516.931053 | Gareth Monger                                                                                                                                                                        |
| 447 |    300.468628 |     36.828742 | Steven Traver                                                                                                                                                                        |
| 448 |    639.586896 |    703.588324 | Margot Michaud                                                                                                                                                                       |
| 449 |    566.402030 |    320.936242 | Chris huh                                                                                                                                                                            |
| 450 |    847.169922 |    670.126074 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 451 |    222.776679 |    770.877940 | Tasman Dixon                                                                                                                                                                         |
| 452 |    448.935079 |    387.925684 | Matt Crook                                                                                                                                                                           |
| 453 |     15.760679 |    693.974037 | Neil Kelley                                                                                                                                                                          |
| 454 |    312.257342 |    369.434804 | Zimices                                                                                                                                                                              |
| 455 |     37.899020 |    785.125297 | Andrew A. Farke                                                                                                                                                                      |
| 456 |    439.494980 |    571.914757 | Ferran Sayol                                                                                                                                                                         |
| 457 |     43.984018 |    295.038104 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 458 |    883.099238 |    633.411044 | T. Michael Keesey                                                                                                                                                                    |
| 459 |    622.573386 |    206.858097 | Tracy A. Heath                                                                                                                                                                       |
| 460 |    531.972688 |    242.409192 | Nobu Tamura                                                                                                                                                                          |
| 461 |    858.058723 |    645.944699 | Steven Traver                                                                                                                                                                        |
| 462 |    878.638268 |    252.169453 | Ferran Sayol                                                                                                                                                                         |
| 463 |     25.841610 |    272.464267 | Margot Michaud                                                                                                                                                                       |
| 464 |    743.271182 |    718.015508 | Gareth Monger                                                                                                                                                                        |
| 465 |    907.699972 |    771.266941 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                                |
| 466 |    750.364366 |    388.030140 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 467 |    559.338865 |     15.150575 | Ferran Sayol                                                                                                                                                                         |
| 468 |    151.535941 |      6.072598 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 469 |    416.809620 |    479.036255 | Chris A. Hamilton                                                                                                                                                                    |
| 470 |    926.160107 |    360.575744 | Margot Michaud                                                                                                                                                                       |
| 471 |    246.291728 |    304.733755 | T. Michael Keesey                                                                                                                                                                    |
| 472 |    982.028767 |    640.524583 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 473 |     80.595225 |    204.450541 | Margot Michaud                                                                                                                                                                       |
| 474 |    974.960851 |    103.427529 | Ferran Sayol                                                                                                                                                                         |
| 475 |    796.217710 |      8.425113 | Steven Coombs                                                                                                                                                                        |
| 476 |    551.192750 |    654.404523 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 477 |    659.341304 |    796.188562 | M Kolmann                                                                                                                                                                            |
| 478 |    176.935085 |    437.756395 | Zimices                                                                                                                                                                              |
| 479 |    137.381831 |    167.475923 | Jagged Fang Designs                                                                                                                                                                  |
| 480 |    625.998728 |    713.840671 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                                            |
| 481 |    731.361426 |    297.037777 | Collin Gross                                                                                                                                                                         |
| 482 |    174.189730 |    327.818568 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                            |
| 483 |    418.196741 |      8.307991 | Matt Dempsey                                                                                                                                                                         |
| 484 |    853.231170 |    215.769828 | Mathilde Cordellier                                                                                                                                                                  |
| 485 |    381.892710 |    692.665121 | Alex Slavenko                                                                                                                                                                        |
| 486 |    736.466690 |    740.404172 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 487 |     86.188525 |    423.012117 | Matt Crook                                                                                                                                                                           |
| 488 |    573.901864 |    182.124440 | Smokeybjb                                                                                                                                                                            |
| 489 |    722.339105 |    583.929672 | Ferran Sayol                                                                                                                                                                         |
| 490 |    840.739874 |    530.022774 | NA                                                                                                                                                                                   |
| 491 |    783.344906 |    220.068535 | Dean Schnabel                                                                                                                                                                        |
| 492 |    765.713500 |    259.976834 | David Orr                                                                                                                                                                            |
| 493 |    578.412437 |    138.463187 | Matt Crook                                                                                                                                                                           |
| 494 |    602.646998 |    671.549641 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 495 |    741.408681 |    642.685010 | Chase Brownstein                                                                                                                                                                     |
| 496 |    278.358314 |    623.461581 | Mathieu Basille                                                                                                                                                                      |
| 497 |    148.417100 |    593.177198 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                                           |
| 498 |    644.382441 |     51.337064 | Beth Reinke                                                                                                                                                                          |
| 499 |    574.007471 |    116.284820 | NA                                                                                                                                                                                   |
| 500 |    802.974164 |    379.978349 | Margot Michaud                                                                                                                                                                       |
| 501 |   1015.061853 |    165.084691 | Ferran Sayol                                                                                                                                                                         |
| 502 |    904.934734 |    348.439221 | Michelle Site                                                                                                                                                                        |
| 503 |    274.399030 |     15.837666 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 504 |    147.723964 |    188.067736 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                                       |
| 505 |    598.174047 |    584.609910 | Zimices                                                                                                                                                                              |
| 506 |    747.966455 |    173.746736 | Steven Traver                                                                                                                                                                        |
| 507 |    717.184982 |    720.100239 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 508 |    747.468754 |    134.265848 | David Orr                                                                                                                                                                            |
| 509 |    792.435320 |    598.334281 | Andrew A. Farke                                                                                                                                                                      |
| 510 |    827.674736 |    221.179328 | Steven Traver                                                                                                                                                                        |
| 511 |    551.644522 |    785.484651 | Alexandre Vong                                                                                                                                                                       |
| 512 |    219.731156 |    171.908822 | T. Michael Keesey                                                                                                                                                                    |
| 513 |    535.019449 |    393.861481 | Nobu Tamura                                                                                                                                                                          |
| 514 |    399.579721 |    245.189361 | Margot Michaud                                                                                                                                                                       |
| 515 |     41.970308 |    132.945844 | Claus Rebler                                                                                                                                                                         |
| 516 |    164.683515 |    663.792171 | NA                                                                                                                                                                                   |
| 517 |    168.566133 |    678.375362 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 518 |    225.604954 |    763.684105 | Jagged Fang Designs                                                                                                                                                                  |
| 519 |    160.069466 |    510.892741 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 520 |    998.698705 |     18.236992 | T. Michael Keesey and Tanetahi                                                                                                                                                       |
| 521 |     33.033528 |    396.585354 | Kai R. Caspar                                                                                                                                                                        |
| 522 |      9.831757 |    124.578023 | NA                                                                                                                                                                                   |
| 523 |    502.967128 |    324.158591 | Matt Crook                                                                                                                                                                           |
| 524 |    455.743974 |    490.209018 | Gareth Monger                                                                                                                                                                        |
| 525 |     57.182685 |    300.562691 | Ferran Sayol                                                                                                                                                                         |
| 526 |     14.994663 |    344.600620 | terngirl                                                                                                                                                                             |
| 527 |    298.552937 |     19.344281 | Joanna Wolfe                                                                                                                                                                         |
| 528 |    525.196721 |    342.684932 | Melissa Broussard                                                                                                                                                                    |
| 529 |    364.026035 |    767.350789 | Margot Michaud                                                                                                                                                                       |
| 530 |    614.118906 |    150.871372 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 531 |    370.796169 |    196.413390 | Scott Reid                                                                                                                                                                           |
| 532 |      7.038063 |    204.054020 | Ferran Sayol                                                                                                                                                                         |
| 533 |    128.319327 |    220.002949 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                                    |
| 534 |     22.917487 |    425.337600 | T. Michael Keesey                                                                                                                                                                    |
| 535 |    635.532006 |    510.607160 | Margot Michaud                                                                                                                                                                       |
| 536 |    871.191674 |    184.042464 | Kamil S. Jaron                                                                                                                                                                       |
| 537 |    295.893381 |    188.768837 | Steven Traver                                                                                                                                                                        |
| 538 |     32.081334 |    555.025690 | Ricardo Araújo                                                                                                                                                                       |
| 539 |    327.935863 |    558.446370 | Chris huh                                                                                                                                                                            |
| 540 |    816.590860 |    175.388101 | V. Deepak                                                                                                                                                                            |
| 541 |    708.311251 |    643.670985 | Tasman Dixon                                                                                                                                                                         |
| 542 |    527.493162 |    586.640985 | Tasman Dixon                                                                                                                                                                         |
| 543 |    874.636290 |     35.176130 | T. Michael Keesey                                                                                                                                                                    |
| 544 |    117.200850 |    531.199798 | NA                                                                                                                                                                                   |
| 545 |    471.075632 |    330.998224 | Matt Crook                                                                                                                                                                           |
| 546 |    608.938035 |    575.884417 | Matthew E. Clapham                                                                                                                                                                   |
| 547 |    116.802603 |    684.935572 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 548 |    245.906571 |    545.104796 | Mathew Wedel                                                                                                                                                                         |
| 549 |    748.627282 |    258.130488 | FunkMonk                                                                                                                                                                             |
| 550 |     47.125586 |    180.137701 | Matt Crook                                                                                                                                                                           |
| 551 |    980.620607 |    138.032446 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
| 552 |    746.283870 |    371.478813 | Steven Traver                                                                                                                                                                        |
| 553 |    907.885585 |    243.102105 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 554 |    235.032421 |    787.035364 | Steven Traver                                                                                                                                                                        |
| 555 |    836.638602 |     14.036877 | L. Shyamal                                                                                                                                                                           |
| 556 |      9.754009 |    311.811863 | Julia B McHugh                                                                                                                                                                       |
| 557 |    146.114032 |    670.271217 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                                  |
| 558 |    254.851791 |     48.331378 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                                    |
| 559 |    201.390667 |    261.681346 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                                      |
| 560 |    374.476353 |    411.463425 | Iain Reid                                                                                                                                                                            |
| 561 |    339.586065 |    744.365295 | Matt Dempsey                                                                                                                                                                         |
| 562 |    572.429438 |    350.154486 | Chris huh                                                                                                                                                                            |
| 563 |    139.221055 |    755.984792 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
| 564 |    568.672544 |    161.236423 | Margot Michaud                                                                                                                                                                       |
| 565 |    172.561231 |    500.985728 | Florian Pfaff                                                                                                                                                                        |
| 566 |    920.565887 |    255.322713 | Gareth Monger                                                                                                                                                                        |
| 567 |    951.559564 |    295.902380 | Margot Michaud                                                                                                                                                                       |
| 568 |    782.460968 |    159.671483 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                                     |
| 569 |    139.650001 |    701.625630 | Christoph Schomburg                                                                                                                                                                  |
| 570 |    550.261136 |    666.448117 | Margot Michaud                                                                                                                                                                       |
| 571 |    203.795624 |    323.225738 | Tasman Dixon                                                                                                                                                                         |
| 572 |    539.419416 |    204.763327 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 573 |    397.098350 |    118.461894 | Scott Hartman                                                                                                                                                                        |
| 574 |    755.511110 |     70.345406 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 575 |    119.372948 |    372.628622 | Zimices / Julián Bayona                                                                                                                                                              |
| 576 |    699.673870 |    246.542770 | Matt Crook                                                                                                                                                                           |
| 577 |    919.078349 |    151.775769 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 578 |    687.579974 |    460.810314 | Matt Crook                                                                                                                                                                           |
| 579 |    671.744511 |    562.543587 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 580 |    213.569439 |    788.044648 | T. Michael Keesey                                                                                                                                                                    |
| 581 |    160.580698 |    198.012865 | Zimices                                                                                                                                                                              |
| 582 |    495.083914 |    259.670350 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                                      |
| 583 |     51.658057 |     17.559843 | Tracy A. Heath                                                                                                                                                                       |
| 584 |    980.273747 |     36.160325 | kreidefossilien.de                                                                                                                                                                   |
| 585 |    751.448117 |    787.024419 | Ingo Braasch                                                                                                                                                                         |
| 586 |    480.395281 |    625.686756 | Chris huh                                                                                                                                                                            |
| 587 |    871.142666 |    173.451543 | Zimices                                                                                                                                                                              |
| 588 |    104.487710 |    220.061186 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 589 |    314.791314 |    550.291923 | Margot Michaud                                                                                                                                                                       |
| 590 |    380.679795 |     84.634851 | Steven Coombs                                                                                                                                                                        |
| 591 |    747.766420 |    430.239988 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 592 |     61.895004 |    784.241408 | Zimices                                                                                                                                                                              |
| 593 |    453.760491 |     39.036065 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 594 |    552.272597 |     80.744877 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
| 595 |    405.710566 |    682.105676 | CNZdenek                                                                                                                                                                             |
| 596 |    562.409940 |    456.619270 | NA                                                                                                                                                                                   |
| 597 |    490.634083 |    471.156952 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                                             |
| 598 |    691.365737 |    370.251344 | Birgit Lang                                                                                                                                                                          |
| 599 |    274.075263 |    302.639494 | Joanna Wolfe                                                                                                                                                                         |
| 600 |    361.686692 |     76.320438 | Mathew Wedel                                                                                                                                                                         |
| 601 |    634.760814 |    567.677941 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 602 |    532.507019 |    402.182187 | Margot Michaud                                                                                                                                                                       |
| 603 |    944.941978 |    260.885777 | Jessica Anne Miller                                                                                                                                                                  |
| 604 |    364.785260 |    773.111315 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
| 605 |    768.414791 |    180.467707 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 606 |    573.973069 |    400.316365 | T. Michael Keesey                                                                                                                                                                    |
| 607 |    227.059899 |    428.190330 | Melissa Broussard                                                                                                                                                                    |
| 608 |     93.585210 |    206.697357 | Margot Michaud                                                                                                                                                                       |
| 609 |    176.307749 |    204.680414 | Zimices                                                                                                                                                                              |
| 610 |    957.508604 |    116.973034 | Emily Willoughby                                                                                                                                                                     |
| 611 |    536.350901 |    434.469959 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                                |
| 612 |    263.388538 |    488.329457 | wsnaccad                                                                                                                                                                             |
| 613 |    647.921045 |     29.415819 | Aline M. Ghilardi                                                                                                                                                                    |
| 614 |    831.543577 |    715.733979 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 615 |    465.245090 |    504.174018 | Scott Hartman                                                                                                                                                                        |
| 616 |    152.910685 |    607.574492 | T. Michael Keesey                                                                                                                                                                    |
| 617 |    192.327092 |    233.757184 | Scott Hartman                                                                                                                                                                        |
| 618 |    252.886791 |    327.659259 | Katie S. Collins                                                                                                                                                                     |
| 619 |    116.189161 |    615.671274 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                                     |
| 620 |    317.754761 |    785.587859 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 621 |    489.492403 |    251.155094 | Adrian Reich                                                                                                                                                                         |
| 622 |    583.889614 |    525.863493 | Matt Crook                                                                                                                                                                           |
| 623 |    681.593729 |    791.196665 | Michelle Site                                                                                                                                                                        |
| 624 |     35.379015 |    319.322490 | Terpsichores                                                                                                                                                                         |
| 625 |    147.005005 |     13.679061 | Tasman Dixon                                                                                                                                                                         |
| 626 |    560.468947 |     99.379933 | NASA                                                                                                                                                                                 |
| 627 |    364.687885 |    628.402253 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
| 628 |    439.071301 |    330.466122 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 629 |     47.465608 |     93.121722 | Mykle Hoban                                                                                                                                                                          |
| 630 |    437.836983 |    534.423132 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 631 |    133.064344 |    550.209652 | Tasman Dixon                                                                                                                                                                         |
| 632 |    364.584851 |    548.334924 | Margot Michaud                                                                                                                                                                       |
| 633 |    860.584000 |    330.314168 | Maija Karala                                                                                                                                                                         |
| 634 |    322.456889 |    609.088316 | Margot Michaud                                                                                                                                                                       |
| 635 |    923.828297 |    276.302198 | Kamil S. Jaron                                                                                                                                                                       |
| 636 |    425.865020 |    515.088109 | Collin Gross                                                                                                                                                                         |
| 637 |    790.315829 |    233.728683 | Joanna Wolfe                                                                                                                                                                         |
| 638 |    387.799408 |     64.541111 | Dmitry Bogdanov                                                                                                                                                                      |
| 639 |      8.893722 |    520.210323 | Jaime Headden                                                                                                                                                                        |
| 640 |    599.970734 |    632.730142 | Steven Traver                                                                                                                                                                        |
| 641 |    610.443718 |    218.206506 | xgirouxb                                                                                                                                                                             |
| 642 |    636.187968 |    158.431702 | L. Shyamal                                                                                                                                                                           |
| 643 |    540.085879 |    503.153965 | Becky Barnes                                                                                                                                                                         |
| 644 |    137.731781 |    189.638927 | T. Michael Keesey                                                                                                                                                                    |
| 645 |    361.613929 |    682.102854 | Renato Santos                                                                                                                                                                        |
| 646 |    142.936035 |    688.956393 | Kamil S. Jaron                                                                                                                                                                       |
| 647 |    220.365399 |    617.651920 | NA                                                                                                                                                                                   |
| 648 |     13.968131 |    140.528510 | Collin Gross                                                                                                                                                                         |
| 649 |    571.586946 |    269.999886 | Tasman Dixon                                                                                                                                                                         |
| 650 |     55.933372 |    225.572024 | NA                                                                                                                                                                                   |
| 651 |    983.343918 |     54.093242 | T. Michael Keesey                                                                                                                                                                    |
| 652 |    242.504556 |    663.884960 | Christine Axon                                                                                                                                                                       |
| 653 |     13.898686 |    174.064991 | Steven Traver                                                                                                                                                                        |
| 654 |     52.817996 |    204.384096 | NA                                                                                                                                                                                   |
| 655 |    727.749807 |    749.464218 | Beth Reinke                                                                                                                                                                          |
| 656 |    772.058187 |     42.469673 | T. Michael Keesey                                                                                                                                                                    |
| 657 |    876.978212 |    468.071788 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                                      |
| 658 |    604.347541 |    119.799770 | Ferran Sayol                                                                                                                                                                         |
| 659 |    557.556879 |    167.433671 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 660 |    417.176666 |    126.576190 | Chris huh                                                                                                                                                                            |
| 661 |    382.500346 |    259.391618 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                                 |
| 662 |    455.622670 |    277.303891 | Michelle Site                                                                                                                                                                        |
| 663 |    146.991692 |     23.645595 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                                |
| 664 |    893.516037 |    276.234229 | Xavier Giroux-Bougard                                                                                                                                                                |
| 665 |    184.429244 |    555.072952 | Ferran Sayol                                                                                                                                                                         |
| 666 |    311.583639 |    386.008798 | Margot Michaud                                                                                                                                                                       |
| 667 |    590.301342 |    618.229215 | Kai R. Caspar                                                                                                                                                                        |
| 668 |    990.459398 |    508.747111 | Zimices                                                                                                                                                                              |
| 669 |    732.966855 |    461.307952 | Zimices                                                                                                                                                                              |
| 670 |    507.240450 |     18.333975 | Tasman Dixon                                                                                                                                                                         |
| 671 |    356.633212 |    795.676367 | Christoph Schomburg                                                                                                                                                                  |
| 672 |    219.075934 |     93.717702 | Yan Wong                                                                                                                                                                             |
| 673 |    277.028868 |    187.400506 | Gareth Monger                                                                                                                                                                        |
| 674 |     75.724738 |    312.876408 | Dmitry Bogdanov                                                                                                                                                                      |
| 675 |    687.927205 |    336.582061 | Scott Hartman                                                                                                                                                                        |
| 676 |    361.111933 |    236.904203 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                         |
| 677 |    993.651020 |    428.565608 | Maija Karala                                                                                                                                                                         |
| 678 |    626.914049 |    452.761352 | Scott Hartman                                                                                                                                                                        |
| 679 |    113.287855 |    435.475482 | Ferran Sayol                                                                                                                                                                         |
| 680 |     71.010606 |    420.870431 | Ferran Sayol                                                                                                                                                                         |
| 681 |    355.314171 |     85.071149 | Margot Michaud                                                                                                                                                                       |
| 682 |    962.456183 |    341.318030 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                             |
| 683 |    871.152088 |    614.009747 | Jaime Headden                                                                                                                                                                        |
| 684 |    907.690789 |    326.406924 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                                          |
| 685 |    980.333718 |    199.099545 | Matt Crook                                                                                                                                                                           |
| 686 |    283.173559 |    502.814958 | Scott Hartman                                                                                                                                                                        |
| 687 |    625.782426 |    743.909848 | Rebecca Groom                                                                                                                                                                        |
| 688 |     40.716028 |    556.825677 | Maija Karala                                                                                                                                                                         |
| 689 |    930.105942 |    269.102934 | Iain Reid                                                                                                                                                                            |
| 690 |    238.943697 |    590.309345 | Matt Crook                                                                                                                                                                           |
| 691 |    444.522858 |    152.945232 | Zimices                                                                                                                                                                              |
| 692 |    840.572812 |    463.234065 | Mathilde Cordellier                                                                                                                                                                  |
| 693 |     64.636921 |    486.089015 | Zimices                                                                                                                                                                              |
| 694 |   1014.191835 |     46.163052 | Zimices                                                                                                                                                                              |
| 695 |    452.595637 |    197.440846 | Tyler Greenfield                                                                                                                                                                     |
| 696 |    177.609415 |    789.561245 | Scott Reid                                                                                                                                                                           |
| 697 |    601.068553 |    496.633896 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 698 |    956.235462 |    621.712053 | Dean Schnabel                                                                                                                                                                        |
| 699 |    116.599096 |    771.310149 | NA                                                                                                                                                                                   |
| 700 |    752.846133 |    616.156840 | Caleb Brown                                                                                                                                                                          |
| 701 |   1010.459770 |    375.659301 | Joedison Rocha                                                                                                                                                                       |
| 702 |    273.360109 |    704.632871 | Jagged Fang Designs                                                                                                                                                                  |
| 703 |    237.060545 |    612.759220 | Matt Crook                                                                                                                                                                           |
| 704 |    116.053121 |    147.764417 | Margot Michaud                                                                                                                                                                       |
| 705 |    611.435588 |    558.112580 | Christoph Schomburg                                                                                                                                                                  |
| 706 |    843.644611 |    790.498612 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 707 |    773.747924 |    419.491880 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                                    |
| 708 |    943.244896 |    512.173135 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 709 |    763.788155 |    627.568327 | Margot Michaud                                                                                                                                                                       |
| 710 |    892.404028 |    229.889837 | Jagged Fang Designs                                                                                                                                                                  |
| 711 |    134.636430 |    738.890676 | Matthew E. Clapham                                                                                                                                                                   |
| 712 |    323.022057 |    571.477531 | Chris huh                                                                                                                                                                            |
| 713 |    601.443124 |    508.070139 | Birgit Lang                                                                                                                                                                          |
| 714 |    993.455599 |    263.300613 | Emily Jane McTavish                                                                                                                                                                  |
| 715 |     48.148074 |    531.628421 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 716 |    958.717058 |    770.335097 | Ferran Sayol                                                                                                                                                                         |
| 717 |    717.866862 |    106.864769 | Matt Crook                                                                                                                                                                           |
| 718 |     11.298929 |    472.116571 | NA                                                                                                                                                                                   |
| 719 |     21.910733 |    711.151642 | Ferran Sayol                                                                                                                                                                         |
| 720 |    641.974829 |    759.485800 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 721 |    596.095598 |    335.604231 | Birgit Lang                                                                                                                                                                          |
| 722 |    192.370302 |    587.432447 | Benjamint444                                                                                                                                                                         |
| 723 |    932.784701 |    492.524744 | Margot Michaud                                                                                                                                                                       |
| 724 |    401.481157 |    344.353869 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 725 |    300.206470 |    307.908123 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                         |
| 726 |    536.740778 |    389.880806 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 727 |    367.197578 |    612.645891 | Ferran Sayol                                                                                                                                                                         |
| 728 |    459.661196 |    784.432995 | Jack Mayer Wood                                                                                                                                                                      |
| 729 |    138.487928 |    277.869879 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 730 |    250.525012 |    162.242005 | Matt Crook                                                                                                                                                                           |
| 731 |    236.261810 |    628.316044 | Gareth Monger                                                                                                                                                                        |
| 732 |    289.988077 |    287.686350 | NA                                                                                                                                                                                   |
| 733 |    914.316563 |    749.149142 | Matt Crook                                                                                                                                                                           |
| 734 |    486.654938 |    447.353076 | Gareth Monger                                                                                                                                                                        |
| 735 |      8.896007 |     32.426576 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 736 |    865.755191 |    625.103204 | Matt Crook                                                                                                                                                                           |
| 737 |    320.443662 |    313.873162 | Margot Michaud                                                                                                                                                                       |
| 738 |    693.859431 |    306.891966 | Scott Reid                                                                                                                                                                           |
| 739 |    963.888458 |    737.739310 | Margot Michaud                                                                                                                                                                       |
| 740 |    349.728352 |    113.091390 | Birgit Lang                                                                                                                                                                          |
| 741 |    836.154325 |    231.462953 | Margot Michaud                                                                                                                                                                       |
| 742 |    980.875942 |    148.866398 | Zimices                                                                                                                                                                              |
| 743 |    748.344296 |    155.211769 | NA                                                                                                                                                                                   |
| 744 |    108.031568 |    652.580230 | Becky Barnes                                                                                                                                                                         |
| 745 |    503.678004 |    386.803608 | Beth Reinke                                                                                                                                                                          |
| 746 |    539.970590 |    342.939564 | Kai R. Caspar                                                                                                                                                                        |
| 747 |     14.824095 |    369.211712 | Matt Crook                                                                                                                                                                           |
| 748 |    239.483733 |    704.978814 | Scott Hartman                                                                                                                                                                        |
| 749 |      8.283285 |    545.138616 | Margot Michaud                                                                                                                                                                       |
| 750 |    260.202964 |     22.455463 | Michelle Site                                                                                                                                                                        |
| 751 |    487.456651 |    205.640629 | Zimices                                                                                                                                                                              |
| 752 |    462.626747 |    630.076953 | Jagged Fang Designs                                                                                                                                                                  |
| 753 |    805.868171 |    239.461245 | Matt Crook                                                                                                                                                                           |
| 754 |    287.776188 |     31.769911 | Yan Wong                                                                                                                                                                             |
| 755 |     65.074593 |    679.238361 | Margot Michaud                                                                                                                                                                       |
| 756 |    936.715302 |    370.677640 | Matt Crook                                                                                                                                                                           |
| 757 |    938.272183 |    470.838841 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 758 |     28.144742 |    768.117072 | Matt Crook                                                                                                                                                                           |
| 759 |    369.498905 |    335.606278 | Jaime Headden                                                                                                                                                                        |
| 760 |     36.102396 |    421.216667 | Tasman Dixon                                                                                                                                                                         |
| 761 |    378.300984 |    608.518406 | Zimices                                                                                                                                                                              |
| 762 |    180.320106 |     27.322544 | C. Abraczinskas                                                                                                                                                                      |
| 763 |    470.502193 |    236.762842 | Kimberly Haddrell                                                                                                                                                                    |
| 764 |    836.225735 |    680.282356 | Ingo Braasch                                                                                                                                                                         |
| 765 |    225.495935 |    570.495305 | Emily Willoughby                                                                                                                                                                     |
| 766 |    407.545579 |    285.190169 | Sarah Werning                                                                                                                                                                        |
| 767 |    640.649023 |    490.717020 | Margot Michaud                                                                                                                                                                       |
| 768 |    370.433805 |    134.212634 | Steven Traver                                                                                                                                                                        |
| 769 |    148.810296 |    791.044763 | Dmitry Bogdanov                                                                                                                                                                      |
| 770 |    693.978563 |    656.895067 | Birgit Lang                                                                                                                                                                          |
| 771 |    105.995989 |    425.065801 | Iain Reid                                                                                                                                                                            |
| 772 |    587.430910 |    631.484101 | Tauana J. Cunha                                                                                                                                                                      |
| 773 |    711.563678 |     98.479371 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                           |
| 774 |     27.307114 |     70.634098 | Jaime Headden                                                                                                                                                                        |
| 775 |      8.370675 |    272.279451 | Margot Michaud                                                                                                                                                                       |
| 776 |    342.702560 |    322.633253 | Jack Mayer Wood                                                                                                                                                                      |
| 777 |    943.360915 |    749.110857 | Birgit Lang                                                                                                                                                                          |
| 778 |     77.078439 |    235.086468 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                                            |
| 779 |    431.297963 |    344.961144 | Danielle Alba                                                                                                                                                                        |
| 780 |    884.955170 |    533.076022 | Zimices                                                                                                                                                                              |
| 781 |    521.854487 |    164.438830 | T. Michael Keesey                                                                                                                                                                    |
| 782 |    308.527593 |    487.024415 | Tasman Dixon                                                                                                                                                                         |
| 783 |    251.758610 |     38.077743 | Milton Tan                                                                                                                                                                           |
| 784 |    304.982581 |    775.990639 | Dmitry Bogdanov                                                                                                                                                                      |
| 785 |    625.049214 |     13.088335 | Ferran Sayol                                                                                                                                                                         |
| 786 |    471.475959 |    468.204214 | Birgit Lang                                                                                                                                                                          |
| 787 |   1018.230001 |    238.353270 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 788 |   1000.192519 |     30.890188 | Margot Michaud                                                                                                                                                                       |
| 789 |    739.775599 |    636.218075 | Matt Crook                                                                                                                                                                           |
| 790 |    168.525578 |    584.281580 | xgirouxb                                                                                                                                                                             |
| 791 |    870.759911 |    660.726552 | NA                                                                                                                                                                                   |
| 792 |    811.166796 |    793.645308 | Zimices                                                                                                                                                                              |
| 793 |    223.165326 |    562.508089 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                        |
| 794 |    624.627346 |    159.621803 | Abraão B. Leite                                                                                                                                                                      |
| 795 |    525.699229 |    663.638135 | Margot Michaud                                                                                                                                                                       |
| 796 |    263.264871 |    316.314546 | T. Michael Keesey (after Tillyard)                                                                                                                                                   |
| 797 |    239.740948 |    772.465768 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 798 |    518.159667 |    745.570487 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 799 |   1012.022554 |    406.566574 | Cesar Julian                                                                                                                                                                         |
| 800 |    759.966728 |    337.294919 | NA                                                                                                                                                                                   |
| 801 |    138.998082 |    605.230643 | Zimices                                                                                                                                                                              |
| 802 |    734.956329 |     32.120458 | Felix Vaux and Steven A. Trewick                                                                                                                                                     |
| 803 |    912.242908 |    221.891091 | NA                                                                                                                                                                                   |
| 804 |     18.452856 |    145.788201 | Jagged Fang Designs                                                                                                                                                                  |
| 805 |    473.975340 |    247.824953 | Sean McCann                                                                                                                                                                          |
| 806 |     82.163554 |    789.320846 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 807 |    929.340285 |    738.292996 | Ferran Sayol                                                                                                                                                                         |
| 808 |     26.167924 |    189.112272 | Margot Michaud                                                                                                                                                                       |
| 809 |    774.285830 |    560.781274 | Gareth Monger                                                                                                                                                                        |
| 810 |    614.471170 |    596.470114 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                                     |
| 811 |    569.208772 |    474.503608 | Ferran Sayol                                                                                                                                                                         |
| 812 |     90.665453 |    214.297934 | Jagged Fang Designs                                                                                                                                                                  |
| 813 |    756.395592 |    582.332910 | Kai R. Caspar                                                                                                                                                                        |
| 814 |    565.958225 |    637.596540 | Gareth Monger                                                                                                                                                                        |
| 815 |    110.590643 |    696.176536 | NA                                                                                                                                                                                   |
| 816 |     64.414326 |    266.480141 | NA                                                                                                                                                                                   |
| 817 |    287.774694 |    163.085394 | T. Michael Keesey                                                                                                                                                                    |
| 818 |     79.339532 |    369.599859 | Qiang Ou                                                                                                                                                                             |
| 819 |    507.184262 |    699.901418 | Jaime Headden                                                                                                                                                                        |
| 820 |    604.505184 |    140.931176 | Ferran Sayol                                                                                                                                                                         |
| 821 |    436.574617 |    498.927091 | Tracy A. Heath                                                                                                                                                                       |
| 822 |    274.738558 |    667.289055 | Matt Crook                                                                                                                                                                           |
| 823 |    453.898948 |    690.096091 | Iain Reid                                                                                                                                                                            |
| 824 |    461.506069 |    520.454976 | Matt Crook                                                                                                                                                                           |
| 825 |    232.804645 |    158.609103 | Matt Crook                                                                                                                                                                           |
| 826 |     35.282043 |    772.343353 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 827 |    478.626020 |    685.869683 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 828 |    466.968130 |     50.690216 | Zimices                                                                                                                                                                              |
| 829 |    450.262807 |     47.094495 | Christine Axon                                                                                                                                                                       |
| 830 |     93.438221 |    145.620761 | T. Michael Keesey                                                                                                                                                                    |
| 831 |    978.631894 |    487.303698 | Tauana J. Cunha                                                                                                                                                                      |
| 832 |    335.874325 |    294.710642 | Jagged Fang Designs                                                                                                                                                                  |
| 833 |    851.927770 |     16.207883 | Ferran Sayol                                                                                                                                                                         |
| 834 |    510.425136 |    214.012095 | T. Michael Keesey                                                                                                                                                                    |
| 835 |    663.193396 |     46.221174 | Birgit Lang                                                                                                                                                                          |
| 836 |    176.479653 |    411.746304 | Yusan Yang                                                                                                                                                                           |
| 837 |    868.901268 |    257.649834 | Jagged Fang Designs                                                                                                                                                                  |
| 838 |     78.746156 |    435.493008 | Dean Schnabel                                                                                                                                                                        |
| 839 |    842.298017 |    471.607916 | Jagged Fang Designs                                                                                                                                                                  |
| 840 |   1002.592493 |    349.354914 | T. Michael Keesey                                                                                                                                                                    |
| 841 |    359.039599 |    555.751849 | Kai R. Caspar                                                                                                                                                                        |
| 842 |    652.012081 |    737.405598 | Oscar Sanisidro                                                                                                                                                                      |
| 843 |    903.745933 |    785.371629 | Gustav Mützel                                                                                                                                                                        |
| 844 |    658.197199 |    339.833958 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                        |
| 845 |   1014.445078 |     80.264378 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 846 |    705.979796 |    651.161686 | Smokeybjb                                                                                                                                                                            |
| 847 |    189.203360 |     42.188589 | NA                                                                                                                                                                                   |
| 848 |    498.666126 |    101.656627 | C. Abraczinskas                                                                                                                                                                      |
| 849 |    958.437267 |    140.487067 | Gareth Monger                                                                                                                                                                        |
| 850 |   1016.484062 |    427.943669 | Birgit Lang                                                                                                                                                                          |
| 851 |    381.556486 |    239.437466 | Margot Michaud                                                                                                                                                                       |
| 852 |    408.418742 |    171.900978 | Margot Michaud                                                                                                                                                                       |
| 853 |   1013.810828 |    532.352869 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 854 |    448.997699 |    797.377786 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 855 |     11.536714 |    445.849494 | Rebecca Groom                                                                                                                                                                        |
| 856 |    314.686665 |    620.149539 | Zimices                                                                                                                                                                              |
| 857 |    566.934320 |    759.787931 | Collin Gross                                                                                                                                                                         |
| 858 |    581.111858 |    508.132598 | Michael Scroggie                                                                                                                                                                     |
| 859 |     63.584516 |    661.040301 | Margot Michaud                                                                                                                                                                       |
| 860 |    917.111574 |    261.764158 | DW Bapst (modified from Bates et al., 2005)                                                                                                                                          |
| 861 |    651.169106 |    331.694421 | Rebecca Groom                                                                                                                                                                        |
| 862 |   1005.614527 |    306.839299 | Chris A. Hamilton                                                                                                                                                                    |
| 863 |    927.775858 |    114.522221 | NA                                                                                                                                                                                   |
| 864 |    130.589137 |    491.954723 | T. Michael Keesey                                                                                                                                                                    |
| 865 |    308.244490 |    796.231850 | Steven Traver                                                                                                                                                                        |
| 866 |    712.547199 |    436.611106 | Gareth Monger                                                                                                                                                                        |
| 867 |    851.681896 |    636.683585 | Margot Michaud                                                                                                                                                                       |
| 868 |    211.271377 |     66.129877 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 869 |    195.400965 |    444.879730 | Yan Wong from illustration by Charles Orbigny                                                                                                                                        |
| 870 |    510.073323 |    781.375131 | Dmitry Bogdanov                                                                                                                                                                      |
| 871 |    393.984798 |    706.164491 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 872 |    104.336130 |    485.258953 | Matus Valach                                                                                                                                                                         |
| 873 |    453.136964 |    444.933272 | David Orr                                                                                                                                                                            |
| 874 |    884.512830 |    293.320607 | Zimices                                                                                                                                                                              |
| 875 |    927.654683 |    130.521204 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                                    |
| 876 |    218.883898 |    723.639783 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 877 |    997.759291 |    373.688296 | Alex Slavenko                                                                                                                                                                        |
| 878 |    628.326515 |    695.242590 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                     |
| 879 |    705.332219 |    313.859852 | Gareth Monger                                                                                                                                                                        |
| 880 |    438.401695 |     57.686840 | Gopal Murali                                                                                                                                                                         |
| 881 |    638.052830 |     94.588393 | Steven Traver                                                                                                                                                                        |
| 882 |    372.912350 |    581.162978 | Chris A. Hamilton                                                                                                                                                                    |
| 883 |    893.588525 |    609.790372 | Michelle Site                                                                                                                                                                        |
| 884 |    261.614176 |    640.249730 | Matt Crook                                                                                                                                                                           |
| 885 |     48.027277 |    758.116203 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                         |
| 886 |    785.030560 |    179.455417 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                                          |
| 887 |    203.234499 |    314.278119 | Zimices                                                                                                                                                                              |
| 888 |    636.159209 |    689.657075 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 889 |    470.732815 |    391.029512 | Alex Slavenko                                                                                                                                                                        |
| 890 |     99.039949 |    794.898320 | Dean Schnabel                                                                                                                                                                        |
| 891 |    450.626560 |    169.839371 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                          |
| 892 |    989.146830 |    260.183040 | Matt Crook                                                                                                                                                                           |
| 893 |    741.579321 |    202.622496 | Zimices                                                                                                                                                                              |
| 894 |    523.416109 |    231.068456 | Mykle Hoban                                                                                                                                                                          |
| 895 |    896.324272 |    634.276469 | Jimmy Bernot                                                                                                                                                                         |
| 896 |    967.175543 |    506.539847 | Raven Amos                                                                                                                                                                           |
| 897 |    434.167505 |    248.980154 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 898 |    968.994159 |    794.124300 | Auckland Museum and T. Michael Keesey                                                                                                                                                |
| 899 |    525.112594 |    326.554946 | Ferran Sayol                                                                                                                                                                         |
| 900 |    261.085910 |    657.849216 | Matt Crook                                                                                                                                                                           |
| 901 |    139.622294 |    490.283834 | T. Michael Keesey                                                                                                                                                                    |
| 902 |   1009.339394 |    784.903936 | Michelle Site                                                                                                                                                                        |
| 903 |    443.399425 |    206.837739 | Birgit Lang                                                                                                                                                                          |
| 904 |    296.170080 |    259.779957 | T. Michael Keesey                                                                                                                                                                    |
| 905 |     21.819105 |    485.691304 | Beth Reinke                                                                                                                                                                          |
| 906 |    250.173974 |    420.817231 | Margot Michaud                                                                                                                                                                       |
| 907 |    509.657673 |    444.012658 | Chris huh                                                                                                                                                                            |
| 908 |     63.446148 |    522.073048 | Matt Wilkins                                                                                                                                                                         |
| 909 |    107.516856 |    624.449957 | Ingo Braasch                                                                                                                                                                         |
| 910 |    682.508607 |    471.928596 | Inessa Voet                                                                                                                                                                          |
| 911 |    297.896653 |    413.794192 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 912 |    316.112146 |    539.761002 | Steven Traver                                                                                                                                                                        |
| 913 |    344.445670 |    617.930581 | Dean Schnabel                                                                                                                                                                        |
| 914 |    689.380843 |    331.414280 | Dave Angelini                                                                                                                                                                        |
| 915 |    433.333064 |    386.233721 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 916 |    486.599977 |    486.744134 | Chloé Schmidt                                                                                                                                                                        |
| 917 |    243.300057 |    539.799778 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                                        |
| 918 |    454.147810 |    289.492200 | NA                                                                                                                                                                                   |
| 919 |    963.154937 |     29.834636 | Andrew A. Farke                                                                                                                                                                      |

    #> Your tweet has been posted!
