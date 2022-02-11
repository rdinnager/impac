
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

Iain Reid, Margot Michaud, Jaime Headden, Chris huh, T. Michael Keesey
(vectorization); Yves Bousquet (photography), Steven Traver, Zimices,
Christoph Schomburg, Jake Warner, Sarah Werning, Emil Schmidt
(vectorized by Maxime Dahirel), T. Michael Keesey, Gabriela
Palomo-Munoz, Mali’o Kodis, photograph from Jersabek et al, 2003, Jack
Mayer Wood, Markus A. Grohme, Alexander Schmidt-Lebuhn, FunkMonk, Mattia
Menchetti, C. Camilo Julián-Caballero, Kanchi Nanjo, Enoch Joseph Wetsy
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, M Kolmann, Matt Crook, Kamil S. Jaron, Andrew A. Farke, shell
lines added by Yan Wong, Gregor Bucher, Max Farnworth, Chris A.
Hamilton, James R. Spotila and Ray Chatterji, Lip Kee Yap (vectorized by
T. Michael Keesey), Joanna Wolfe, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Ellen Edmonson (illustration)
and Timothy J. Bartley (silhouette), Curtis Clark and T. Michael Keesey,
Cristopher Silva, Stuart Humphries, Maija Karala, Mathieu Pélissié,
Crystal Maier, Scott Hartman, Mathew Callaghan, Dmitry Bogdanov, Armin
Reindl, Chris Jennings (Risiatto), Dmitry Bogdanov (vectorized by T.
Michael Keesey), Noah Schlottman, photo by Casey Dunn, Gareth Monger,
Matt Dempsey, Eric Moody, Ferran Sayol, Conty (vectorized by T. Michael
Keesey), Óscar San-Isidro (vectorized by T. Michael Keesey), Jagged Fang
Designs, Ghedo and T. Michael Keesey, Dmitry Bogdanov and FunkMonk
(vectorized by T. Michael Keesey), Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Noah Schlottman, DW Bapst, modified from Ishitani et al. 2016, L.
Shyamal, Sharon Wegner-Larsen, Michael Scroggie, JCGiron, Melissa
Broussard, Caleb M. Brown, Lily Hughes, Trond R. Oskars, Yan Wong from
SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo), Smokeybjb,
Terpsichores, NOAA (vectorized by T. Michael Keesey), Dennis C. Murphy,
after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
david maas / dave hone, Jessica Anne Miller, Maxime Dahirel, Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., Christine Axon, Mariana Ruiz (vectorized
by T. Michael Keesey), Birgit Lang, Christopher Laumer (vectorized by T.
Michael Keesey), Noah Schlottman, photo by Martin V. Sørensen, Dein
Freund der Baum (vectorized by T. Michael Keesey), Yan Wong, Hans
Hillewaert (vectorized by T. Michael Keesey), Rebecca Groom, T.
Tischler, Eduard Solà Vázquez, vectorised by Yan Wong, Juan Carlos Jerí,
Sam Droege (photo) and T. Michael Keesey (vectorization), Michelle Site,
Rene Martin, Harold N Eyster, Alexandre Vong, A. R. McCulloch
(vectorized by T. Michael Keesey), Robert Bruce Horsfall (vectorized by
T. Michael Keesey), Beth Reinke, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, xgirouxb, Martin
R. Smith, Yusan Yang, Andrew A. Farke, T. Michael Keesey, from a
photograph by Thea Boodhoo, Jimmy Bernot, Mathilde Cordellier, Collin
Gross, Jaime Headden (vectorized by T. Michael Keesey), Noah Schlottman,
photo from Casey Dunn, Francis de Laporte de Castelnau (vectorized by T.
Michael Keesey), Mark Hofstetter (vectorized by T. Michael Keesey),
Tracy A. Heath, Robert Gay, Benjamin Monod-Broca, Darren Naish
(vectorize by T. Michael Keesey), Hans Hillewaert, Aline M. Ghilardi,
Falconaumanni and T. Michael Keesey, Ekaterina Kopeykina (vectorized by
T. Michael Keesey), Yan Wong from wikipedia drawing (PD: Pearson Scott
Foresman), Jose Carlos Arenas-Monroy, Hanyong Pu, Yoshitsugu Kobayashi,
Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia &
T. Michael Keesey, Dean Schnabel, Robbie N. Cada (vectorized by T.
Michael Keesey), Noah Schlottman, photo by Hans De Blauwe, NASA,
S.Martini, T. Michael Keesey (vectorization) and Nadiatalent
(photography), Alex Slavenko, Verdilak, Mali’o Kodis, drawing by Manvir
Singh, E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey), Mr E?
(vectorized by T. Michael Keesey), Matt Martyniuk, Heinrich Harder
(vectorized by T. Michael Keesey), Maky (vectorization), Gabriella
Skollar (photography), Rebecca Lewis (editing), Anthony Caravaggi,
Milton Tan, Gopal Murali, Christian A. Masnaghetti, CNZdenek, Nobu
Tamura (vectorized by T. Michael Keesey), Lukasiniho, Cesar Julian, Sean
McCann, Pearson Scott Foresman (vectorized by T. Michael Keesey), Tasman
Dixon, Rafael Maia, Elisabeth Östman, Felix Vaux, Marie Russell,
AnAgnosticGod (vectorized by T. Michael Keesey), Manabu Bessho-Uehara,
Neil Kelley, M. A. Broussard, Sherman Foote Denton (illustration, 1897)
and Timothy J. Bartley (silhouette), Jon M Laurent, Emily Willoughby,
Kent Sorgon, Moussa Direct Ltd. (photography) and T. Michael Keesey
(vectorization), Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Mariana
Ruiz Villarreal, Oliver Griffith, Martin R. Smith, after Skovsted et al
2015, Jaime A. Headden (vectorized by T. Michael Keesey), Scott Hartman
(modified by T. Michael Keesey), Katie S. Collins, Brad McFeeters
(vectorized by T. Michael Keesey), Chloé Schmidt, Ignacio Contreras, M.
Garfield & K. Anderson (modified by T. Michael Keesey), Diana Pomeroy,
Arthur S. Brum, Steve Hillebrand/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), Carlos Cano-Barbacil, Matt
Celeskey, Richard J. Harris, Smokeybjb (modified by T. Michael Keesey),
Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Owen Jones, Scott Hartman (vectorized by T. Michael
Keesey), François Michonneau, Mali’o Kodis, image from Higgins and
Kristensen, 1986, Steven Blackwood, Renato Santos, Julio Garza, Steven
Coombs, (after Spotila 2004), Ingo Braasch, Mali’o Kodis, photograph by
P. Funch and R.M. Kristensen, Cagri Cevrim, Kosta Mumcuoglu (vectorized
by T. Michael Keesey), Xavier A. Jenkins, Gabriel Ugueto, Mathieu
Basille, Chris Hay, Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Matthew E.
Clapham, Danielle Alba, Nobu Tamura, vectorized by Zimices, Todd
Marshall, vectorized by Zimices,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Kai R. Caspar, Agnello Picorelli,
Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Konsta Happonen, John Gould (vectorized
by T. Michael Keesey), Felix Vaux and Steven A. Trewick, Tony Ayling
(vectorized by T. Michael Keesey), Roberto Díaz Sibaja, David Sim
(photograph) and T. Michael Keesey (vectorization), Ernst Haeckel
(vectorized by T. Michael Keesey), Cristina Guijarro, Raven Amos, Pedro
de Siracusa, FJDegrange, Jiekun He, Andrew A. Farke, modified from
original by Robert Bruce Horsfall, from Scott 1912, Danny Cicchetti
(vectorized by T. Michael Keesey), DW Bapst (Modified from Bulman,
1964), Sam Fraser-Smith (vectorized by T. Michael Keesey), Maxwell
Lefroy (vectorized by T. Michael Keesey), V. Deepak, Matt Martyniuk
(vectorized by T. Michael Keesey), Mason McNair, Samanta Orellana, Nobu
Tamura (modified by T. Michael Keesey), M Hutchinson, Bruno C.
Vellutini, Shyamal, Tony Ayling, Tomas Willems (vectorized by T. Michael
Keesey), Servien (vectorized by T. Michael Keesey), DW Bapst (modified
from Bulman, 1970), Notafly (vectorized by T. Michael Keesey), Fernando
Carezzano, Pete Buchholz, Chuanixn Yu, Jaime Chirinos (vectorized by T.
Michael Keesey), Jean-Raphaël Guillaumin (photography) and T. Michael
Keesey (vectorization), Scott Reid, Christopher Watson (photo) and T.
Michael Keesey (vectorization), Inessa Voet, Cathy, Eyal Bartov, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), terngirl, Lauren Sumner-Rooney, A. H. Baldwin
(vectorized by T. Michael Keesey), Michael “FunkMonk” B. H. (vectorized
by T. Michael Keesey), Antonov (vectorized by T. Michael Keesey), Xavier
Giroux-Bougard, Jakovche, E. Lear, 1819 (vectorization by Yan Wong),
Bill Bouton (source photo) & T. Michael Keesey (vectorization), Tauana
J. Cunha, Natalie Claunch, Sergio A. Muñoz-Gómez, Burton Robert, USFWS,
Dave Souza (vectorized by T. Michael Keesey), Jebulon (vectorized by T.
Michael Keesey), Apokryltaros (vectorized by T. Michael Keesey),
Smokeybjb (vectorized by T. Michael Keesey), Mathew Wedel, Lukas
Panzarin, Gustav Mützel, T. Michael Keesey (after Tillyard), Chase
Brownstein, Cristian Osorio & Paula Carrera, Proyecto Carnivoros
Australes (www.carnivorosaustrales.org), Craig Dylke, Steven Coombs
(vectorized by T. Michael Keesey), Nobu Tamura, Jessica Rick, Siobhon
Egan, Joe Schneid (vectorized by T. Michael Keesey), Gabriel Lio,
vectorized by Zimices, David Orr, Oscar Sanisidro, Mali’o Kodis, image
from the Biodiversity Heritage Library, Cyril Matthey-Doret, adapted
from Bernard Chaubet, FunkMonk \[Michael B.H.\] (modified by T. Michael
Keesey), T. Michael Keesey (from a photograph by Frank Glaw, Jörn
Köhler, Ted M. Townsend & Miguel Vences)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    396.695541 |     67.345764 | Iain Reid                                                                                                                                                                       |
|   2 |    421.966413 |    515.615953 | Margot Michaud                                                                                                                                                                  |
|   3 |    778.029788 |    288.933724 | Jaime Headden                                                                                                                                                                   |
|   4 |    667.327471 |    409.586360 | Chris huh                                                                                                                                                                       |
|   5 |    612.005648 |     79.485433 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                                  |
|   6 |    442.057639 |    205.384046 | Chris huh                                                                                                                                                                       |
|   7 |    346.691096 |    155.775513 | Steven Traver                                                                                                                                                                   |
|   8 |    140.865464 |    767.803439 | Zimices                                                                                                                                                                         |
|   9 |    637.188981 |    634.382345 | Christoph Schomburg                                                                                                                                                             |
|  10 |    125.133117 |    116.059201 | Jake Warner                                                                                                                                                                     |
|  11 |    921.657476 |    246.090901 | Chris huh                                                                                                                                                                       |
|  12 |    323.144054 |    478.372264 | NA                                                                                                                                                                              |
|  13 |    495.479381 |    380.208985 | Sarah Werning                                                                                                                                                                   |
|  14 |    480.194191 |    662.414810 | NA                                                                                                                                                                              |
|  15 |    989.832929 |    635.311213 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                     |
|  16 |     81.510551 |    269.105282 | Chris huh                                                                                                                                                                       |
|  17 |    162.534389 |    243.255602 | T. Michael Keesey                                                                                                                                                               |
|  18 |    522.550574 |    551.578475 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  19 |     35.364417 |    654.863685 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                              |
|  20 |    287.501332 |    606.163664 | Zimices                                                                                                                                                                         |
|  21 |    232.894646 |    467.242854 | Jack Mayer Wood                                                                                                                                                                 |
|  22 |    331.473224 |    301.277846 | T. Michael Keesey                                                                                                                                                               |
|  23 |     75.611899 |    172.020127 | Markus A. Grohme                                                                                                                                                                |
|  24 |    844.013350 |    181.048737 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
|  25 |    956.671308 |     65.272972 | FunkMonk                                                                                                                                                                        |
|  26 |    684.065388 |    708.337894 | Mattia Menchetti                                                                                                                                                                |
|  27 |    574.467271 |    215.774951 | NA                                                                                                                                                                              |
|  28 |    532.042335 |    258.830369 | C. Camilo Julián-Caballero                                                                                                                                                      |
|  29 |    859.957624 |    533.514906 | Kanchi Nanjo                                                                                                                                                                    |
|  30 |    562.906711 |    157.024251 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey              |
|  31 |    885.791668 |    279.762100 | M Kolmann                                                                                                                                                                       |
|  32 |    894.653867 |    668.995106 | Matt Crook                                                                                                                                                                      |
|  33 |    297.615018 |    689.325399 | Kamil S. Jaron                                                                                                                                                                  |
|  34 |     59.305143 |    370.135017 | Matt Crook                                                                                                                                                                      |
|  35 |    853.487425 |    749.889309 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                  |
|  36 |    645.362240 |    199.223509 | Gregor Bucher, Max Farnworth                                                                                                                                                    |
|  37 |    908.757291 |    145.148559 | Chris A. Hamilton                                                                                                                                                               |
|  38 |    247.344467 |    229.871474 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  39 |    832.803955 |     35.107878 | James R. Spotila and Ray Chatterji                                                                                                                                              |
|  40 |    472.825795 |    309.662349 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                                   |
|  41 |    511.684026 |    764.232184 | Joanna Wolfe                                                                                                                                                                    |
|  42 |     96.788678 |    484.407187 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                                        |
|  43 |    169.389880 |    636.389842 | Matt Crook                                                                                                                                                                      |
|  44 |    238.900139 |    552.423364 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                               |
|  45 |    718.946152 |     67.499152 | Curtis Clark and T. Michael Keesey                                                                                                                                              |
|  46 |    690.251332 |    541.596798 | Margot Michaud                                                                                                                                                                  |
|  47 |    942.117998 |    323.806120 | Cristopher Silva                                                                                                                                                                |
|  48 |    449.249727 |    429.233261 | Chris huh                                                                                                                                                                       |
|  49 |    399.803609 |    737.063881 | Steven Traver                                                                                                                                                                   |
|  50 |    387.023797 |    386.047101 | Stuart Humphries                                                                                                                                                                |
|  51 |    107.836922 |     58.158845 | Maija Karala                                                                                                                                                                    |
|  52 |    359.613002 |    226.656740 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  53 |    264.435327 |    768.678005 | Markus A. Grohme                                                                                                                                                                |
|  54 |    210.810448 |    102.117576 | Mathieu Pélissié                                                                                                                                                                |
|  55 |    802.433507 |    163.744378 | Crystal Maier                                                                                                                                                                   |
|  56 |    918.668773 |    403.291430 | Margot Michaud                                                                                                                                                                  |
|  57 |     78.858756 |    550.239580 | NA                                                                                                                                                                              |
|  58 |    227.745388 |    389.545133 | Scott Hartman                                                                                                                                                                   |
|  59 |    574.631249 |    732.107106 | Mathew Callaghan                                                                                                                                                                |
|  60 |    649.977045 |    651.878312 | Dmitry Bogdanov                                                                                                                                                                 |
|  61 |    859.747893 |    786.236513 | Armin Reindl                                                                                                                                                                    |
|  62 |    457.974658 |    686.073186 | Chris Jennings (Risiatto)                                                                                                                                                       |
|  63 |    769.159468 |    736.756033 | Matt Crook                                                                                                                                                                      |
|  64 |    190.225732 |    712.980256 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  65 |    655.524566 |    296.222835 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
|  66 |    558.030278 |     67.905306 | Gareth Monger                                                                                                                                                                   |
|  67 |    494.937669 |     28.541650 | Matt Dempsey                                                                                                                                                                    |
|  68 |    465.237318 |    106.057103 | Eric Moody                                                                                                                                                                      |
|  69 |    744.884860 |    228.856310 | Ferran Sayol                                                                                                                                                                    |
|  70 |    259.799048 |     26.127127 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  71 |    365.742664 |     20.777660 | Margot Michaud                                                                                                                                                                  |
|  72 |    649.404296 |    586.331614 | Armin Reindl                                                                                                                                                                    |
|  73 |    640.626186 |    492.901623 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
|  74 |     61.928793 |    212.494347 | Scott Hartman                                                                                                                                                                   |
|  75 |    432.623499 |    635.961976 | T. Michael Keesey                                                                                                                                                               |
|  76 |    793.407658 |    588.634991 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                              |
|  77 |    574.036621 |      8.445039 | Jagged Fang Designs                                                                                                                                                             |
|  78 |    991.180662 |    744.768451 | Steven Traver                                                                                                                                                                   |
|  79 |    711.789786 |    173.262674 | Ghedo and T. Michael Keesey                                                                                                                                                     |
|  80 |    296.709797 |    351.189790 | Gareth Monger                                                                                                                                                                   |
|  81 |    264.819623 |    202.222896 | Ferran Sayol                                                                                                                                                                    |
|  82 |     73.218822 |    456.564790 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                                  |
|  83 |    992.650583 |    115.885253 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
|  84 |    751.575614 |    671.366554 | Matt Crook                                                                                                                                                                      |
|  85 |      8.013051 |    511.219468 | Noah Schlottman                                                                                                                                                                 |
|  86 |     83.246246 |    731.942080 | Zimices                                                                                                                                                                         |
|  87 |    810.561961 |    453.479012 | Steven Traver                                                                                                                                                                   |
|  88 |    697.279971 |    187.790846 | Gareth Monger                                                                                                                                                                   |
|  89 |    175.681896 |      3.550680 | Markus A. Grohme                                                                                                                                                                |
|  90 |    984.779966 |    202.242504 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                                    |
|  91 |    370.437572 |    603.205566 | L. Shyamal                                                                                                                                                                      |
|  92 |    468.263570 |    344.480195 | Sharon Wegner-Larsen                                                                                                                                                            |
|  93 |    828.899957 |    244.259605 | NA                                                                                                                                                                              |
|  94 |     91.007923 |    231.628295 | Michael Scroggie                                                                                                                                                                |
|  95 |    145.294159 |    422.357256 | Matt Crook                                                                                                                                                                      |
|  96 |    959.758609 |    446.312700 | JCGiron                                                                                                                                                                         |
|  97 |    926.860634 |    204.298592 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  98 |    751.924540 |    131.394003 | Melissa Broussard                                                                                                                                                               |
|  99 |    559.668474 |    707.728524 | Caleb M. Brown                                                                                                                                                                  |
| 100 |    238.650917 |    162.154611 | T. Michael Keesey                                                                                                                                                               |
| 101 |    346.629111 |    545.499141 | Markus A. Grohme                                                                                                                                                                |
| 102 |    374.747840 |    634.828526 | Lily Hughes                                                                                                                                                                     |
| 103 |     83.554828 |    437.392669 | Zimices                                                                                                                                                                         |
| 104 |    528.556782 |     69.449422 | Scott Hartman                                                                                                                                                                   |
| 105 |    242.335302 |     32.195762 | Scott Hartman                                                                                                                                                                   |
| 106 |    499.475050 |    306.670947 | Chris huh                                                                                                                                                                       |
| 107 |    774.591850 |    702.183260 | Matt Crook                                                                                                                                                                      |
| 108 |    648.866891 |     55.816393 | Trond R. Oskars                                                                                                                                                                 |
| 109 |    785.045869 |     66.604866 | NA                                                                                                                                                                              |
| 110 |    838.239789 |    634.411296 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                                         |
| 111 |    778.796672 |      2.767324 | Smokeybjb                                                                                                                                                                       |
| 112 |    452.646255 |    391.200620 | Terpsichores                                                                                                                                                                    |
| 113 |    243.922113 |    655.325820 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                          |
| 114 |    956.619421 |    486.471957 | Gareth Monger                                                                                                                                                                   |
| 115 |    200.294881 |    150.439567 | Zimices                                                                                                                                                                         |
| 116 |    283.259107 |    114.889632 | Armin Reindl                                                                                                                                                                    |
| 117 |    866.617020 |    211.903060 | Michael Scroggie                                                                                                                                                                |
| 118 |    983.732137 |    376.511334 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 119 |     11.031697 |    289.735554 | Steven Traver                                                                                                                                                                   |
| 120 |    700.795959 |    484.886977 | T. Michael Keesey                                                                                                                                                               |
| 121 |    944.119718 |    561.881974 | Sarah Werning                                                                                                                                                                   |
| 122 |    516.065865 |    443.780894 | david maas / dave hone                                                                                                                                                          |
| 123 |     33.213872 |    114.316544 | Matt Crook                                                                                                                                                                      |
| 124 |    806.760488 |    615.114198 | Jessica Anne Miller                                                                                                                                                             |
| 125 |    859.372966 |    607.345415 | FunkMonk                                                                                                                                                                        |
| 126 |    901.520080 |      5.332594 | Kamil S. Jaron                                                                                                                                                                  |
| 127 |    831.624361 |    102.785217 | Maxime Dahirel                                                                                                                                                                  |
| 128 |    581.233133 |    727.860657 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                      |
| 129 |    700.170168 |    604.064842 | Scott Hartman                                                                                                                                                                   |
| 130 |     73.514006 |     10.406672 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 131 |    526.371402 |    183.927435 | Christine Axon                                                                                                                                                                  |
| 132 |    488.055845 |    152.761479 | Gareth Monger                                                                                                                                                                   |
| 133 |    726.365897 |    333.612217 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                                  |
| 134 |    560.535467 |    493.320760 | Birgit Lang                                                                                                                                                                     |
| 135 |    433.186943 |    172.974537 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                            |
| 136 |    266.374290 |    572.117164 | NA                                                                                                                                                                              |
| 137 |    451.829452 |    790.985012 | Zimices                                                                                                                                                                         |
| 138 |    705.586539 |    140.668944 | Birgit Lang                                                                                                                                                                     |
| 139 |    851.753836 |    358.414190 | FunkMonk                                                                                                                                                                        |
| 140 |    971.960628 |     39.542878 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                    |
| 141 |    572.554733 |    650.843195 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                          |
| 142 |    566.183200 |    662.413667 | Yan Wong                                                                                                                                                                        |
| 143 |    892.367991 |    486.363273 | T. Michael Keesey                                                                                                                                                               |
| 144 |    407.690092 |    492.428570 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 145 |    238.396771 |    297.278460 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                                    |
| 146 |    314.937334 |    630.178216 | Margot Michaud                                                                                                                                                                  |
| 147 |    181.136646 |    365.949795 | Rebecca Groom                                                                                                                                                                   |
| 148 |    352.489353 |    522.037898 | T. Tischler                                                                                                                                                                     |
| 149 |    884.969713 |    629.562593 | Zimices                                                                                                                                                                         |
| 150 |    217.595130 |     64.161940 | Yan Wong                                                                                                                                                                        |
| 151 |    884.863514 |    207.400437 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                                     |
| 152 |    597.550540 |    355.965147 | Zimices                                                                                                                                                                         |
| 153 |    367.877569 |    454.913451 | Juan Carlos Jerí                                                                                                                                                                |
| 154 |     86.779456 |    629.369950 | Kamil S. Jaron                                                                                                                                                                  |
| 155 |    958.083408 |    791.595672 | Jagged Fang Designs                                                                                                                                                             |
| 156 |    398.830810 |    618.135204 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 157 |    312.548958 |    378.689656 | Michelle Site                                                                                                                                                                   |
| 158 |    102.254928 |    286.135785 | Rene Martin                                                                                                                                                                     |
| 159 |    288.761568 |    533.311066 | Harold N Eyster                                                                                                                                                                 |
| 160 |    287.723631 |     15.912674 | Alexandre Vong                                                                                                                                                                  |
| 161 |    654.075536 |    132.179715 | Scott Hartman                                                                                                                                                                   |
| 162 |     84.284912 |    518.993120 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                               |
| 163 |    328.321789 |    497.904194 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                         |
| 164 |     73.116107 |    512.048916 | Maija Karala                                                                                                                                                                    |
| 165 |    650.563905 |    284.121098 | Beth Reinke                                                                                                                                                                     |
| 166 |    546.539098 |    255.743371 | NA                                                                                                                                                                              |
| 167 |    979.436190 |    252.211519 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 168 |    475.508580 |    230.238885 | xgirouxb                                                                                                                                                                        |
| 169 |    440.625448 |    576.497292 | Martin R. Smith                                                                                                                                                                 |
| 170 |    387.185762 |    517.306619 | Margot Michaud                                                                                                                                                                  |
| 171 |    565.084129 |    337.195180 | Yusan Yang                                                                                                                                                                      |
| 172 |    237.103141 |     60.297450 | Andrew A. Farke                                                                                                                                                                 |
| 173 |    999.938661 |    465.591522 | NA                                                                                                                                                                              |
| 174 |    956.372605 |     13.943867 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 175 |    261.287021 |     40.231698 | Steven Traver                                                                                                                                                                   |
| 176 |    676.928419 |    100.681943 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                            |
| 177 |     38.613633 |    133.764652 | Jimmy Bernot                                                                                                                                                                    |
| 178 |    890.297714 |    461.554911 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 179 |    976.827183 |    138.161229 | Gareth Monger                                                                                                                                                                   |
| 180 |     28.945431 |    141.820042 | Zimices                                                                                                                                                                         |
| 181 |    404.263089 |     75.780850 | Mathilde Cordellier                                                                                                                                                             |
| 182 |    543.980444 |    687.060144 | Matt Crook                                                                                                                                                                      |
| 183 |    343.517880 |    101.101608 | Harold N Eyster                                                                                                                                                                 |
| 184 |    367.736447 |    280.793162 | NA                                                                                                                                                                              |
| 185 |    760.390452 |    790.616285 | Matt Crook                                                                                                                                                                      |
| 186 |    864.824919 |    638.949447 | Matt Crook                                                                                                                                                                      |
| 187 |    540.064706 |    658.153839 | Michael Scroggie                                                                                                                                                                |
| 188 |    360.552524 |    764.385987 | Collin Gross                                                                                                                                                                    |
| 189 |    110.193291 |    609.564013 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                                 |
| 190 |     44.206840 |    739.895098 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
| 191 |    400.211524 |    253.693394 | Steven Traver                                                                                                                                                                   |
| 192 |    709.621786 |    248.065759 | Zimices                                                                                                                                                                         |
| 193 |   1008.815589 |    345.377518 | Matt Crook                                                                                                                                                                      |
| 194 |    498.430780 |    400.490304 | Chris huh                                                                                                                                                                       |
| 195 |    122.168348 |    523.364412 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                               |
| 196 |    898.408834 |    689.001468 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                               |
| 197 |    230.032056 |    353.856541 | Ferran Sayol                                                                                                                                                                    |
| 198 |     92.231764 |    686.500858 | Matt Crook                                                                                                                                                                      |
| 199 |     46.063009 |    761.620488 | Tracy A. Heath                                                                                                                                                                  |
| 200 |    697.132635 |    118.236782 | Matt Crook                                                                                                                                                                      |
| 201 |    525.017317 |    645.239919 | Zimices                                                                                                                                                                         |
| 202 |     10.538509 |    328.226053 | Margot Michaud                                                                                                                                                                  |
| 203 |    875.027530 |    438.050150 | Collin Gross                                                                                                                                                                    |
| 204 |    718.720719 |    461.638517 | Margot Michaud                                                                                                                                                                  |
| 205 |    297.047798 |     80.309190 | Robert Gay                                                                                                                                                                      |
| 206 |   1000.929869 |    266.618112 | Benjamin Monod-Broca                                                                                                                                                            |
| 207 |    269.179692 |    362.324595 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                   |
| 208 |    754.837272 |     22.258292 | Hans Hillewaert                                                                                                                                                                 |
| 209 |    473.236334 |    405.291673 | Sarah Werning                                                                                                                                                                   |
| 210 |    326.241749 |    647.687154 | Aline M. Ghilardi                                                                                                                                                               |
| 211 |    287.605760 |     65.522137 | Falconaumanni and T. Michael Keesey                                                                                                                                             |
| 212 |    129.652142 |     23.265463 | Birgit Lang                                                                                                                                                                     |
| 213 |    851.013318 |    455.126252 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 214 |    848.576003 |    264.646674 | Scott Hartman                                                                                                                                                                   |
| 215 |      6.891499 |    435.348722 | T. Michael Keesey                                                                                                                                                               |
| 216 |    956.496957 |    576.689731 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                           |
| 217 |    533.857333 |    119.328668 | Matt Crook                                                                                                                                                                      |
| 218 |    602.936317 |    326.100792 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                    |
| 219 |    886.865200 |    224.653258 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 220 |    770.463357 |     96.544790 | Zimices                                                                                                                                                                         |
| 221 |    840.413730 |    139.931185 | Jake Warner                                                                                                                                                                     |
| 222 |    908.383287 |    365.840014 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                                     |
| 223 |    995.929150 |     36.669083 | Margot Michaud                                                                                                                                                                  |
| 224 |    887.204597 |    425.576129 | Dean Schnabel                                                                                                                                                                   |
| 225 |    935.532361 |     95.739137 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 226 |    174.707944 |    349.787299 | Collin Gross                                                                                                                                                                    |
| 227 |    841.449573 |    445.444769 | James R. Spotila and Ray Chatterji                                                                                                                                              |
| 228 |    616.176146 |    255.230318 | Zimices                                                                                                                                                                         |
| 229 |    459.920239 |    457.664360 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 230 |    964.007495 |    711.438304 | NA                                                                                                                                                                              |
| 231 |    718.024770 |    190.390390 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                                        |
| 232 |    543.594122 |    519.747210 | NASA                                                                                                                                                                            |
| 233 |    541.902678 |     41.911275 | S.Martini                                                                                                                                                                       |
| 234 |    667.588570 |     12.893747 | Margot Michaud                                                                                                                                                                  |
| 235 |    686.629287 |    756.900558 | Jagged Fang Designs                                                                                                                                                             |
| 236 |    175.477799 |    333.107387 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                 |
| 237 |    134.050248 |    368.593347 | Smokeybjb                                                                                                                                                                       |
| 238 |    284.351126 |    104.446186 | Margot Michaud                                                                                                                                                                  |
| 239 |    935.492452 |    569.124617 | Jagged Fang Designs                                                                                                                                                             |
| 240 |    976.517701 |    397.197428 | Alex Slavenko                                                                                                                                                                   |
| 241 |    768.549627 |    360.425969 | NA                                                                                                                                                                              |
| 242 |    724.584868 |    660.677962 | Verdilak                                                                                                                                                                        |
| 243 |    104.161701 |    317.582868 | Chris huh                                                                                                                                                                       |
| 244 |    558.207758 |    794.131025 | Margot Michaud                                                                                                                                                                  |
| 245 |    861.009452 |    585.811303 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                           |
| 246 |    414.215171 |    777.955923 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                      |
| 247 |    682.468243 |    329.390848 | Ferran Sayol                                                                                                                                                                    |
| 248 |    966.591688 |    531.997745 | Steven Traver                                                                                                                                                                   |
| 249 |    158.593032 |    331.735325 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                                         |
| 250 |    342.113298 |    416.472235 | Beth Reinke                                                                                                                                                                     |
| 251 |    457.674663 |    734.948935 | Birgit Lang                                                                                                                                                                     |
| 252 |    231.643437 |    646.603730 | T. Michael Keesey                                                                                                                                                               |
| 253 |    529.938621 |    426.224434 | Matt Martyniuk                                                                                                                                                                  |
| 254 |    298.880975 |    651.793373 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                               |
| 255 |    669.013966 |     32.995209 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                  |
| 256 |    366.757743 |    244.408528 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 257 |    596.485602 |    387.872893 | NA                                                                                                                                                                              |
| 258 |    741.989329 |    499.166959 | Anthony Caravaggi                                                                                                                                                               |
| 259 |    628.585520 |    452.343716 | Milton Tan                                                                                                                                                                      |
| 260 |     92.392185 |    653.240748 | Scott Hartman                                                                                                                                                                   |
| 261 |    959.594519 |    279.386138 | Gopal Murali                                                                                                                                                                    |
| 262 |   1010.710281 |    237.987817 | Birgit Lang                                                                                                                                                                     |
| 263 |    988.838350 |    290.508826 | NA                                                                                                                                                                              |
| 264 |    338.779737 |    408.460598 | Christian A. Masnaghetti                                                                                                                                                        |
| 265 |    863.420383 |    239.185551 | Gareth Monger                                                                                                                                                                   |
| 266 |     33.555791 |    573.260819 | Kamil S. Jaron                                                                                                                                                                  |
| 267 |    417.943890 |    476.965297 | CNZdenek                                                                                                                                                                        |
| 268 |    670.249521 |    563.831061 | Ferran Sayol                                                                                                                                                                    |
| 269 |    524.065003 |      3.077282 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 270 |   1014.717514 |    378.274085 | NA                                                                                                                                                                              |
| 271 |    448.784531 |    273.133863 | Lukasiniho                                                                                                                                                                      |
| 272 |    666.619233 |    454.713391 | Steven Traver                                                                                                                                                                   |
| 273 |    540.229542 |    348.588199 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 274 |    424.734597 |    367.120658 | Jagged Fang Designs                                                                                                                                                             |
| 275 |    218.906600 |    678.333177 | Cesar Julian                                                                                                                                                                    |
| 276 |    766.756179 |    528.427447 | Sean McCann                                                                                                                                                                     |
| 277 |    826.498945 |    357.889411 | Chris huh                                                                                                                                                                       |
| 278 |   1011.325992 |    418.467142 | Margot Michaud                                                                                                                                                                  |
| 279 |    570.742705 |    294.146456 | Markus A. Grohme                                                                                                                                                                |
| 280 |    887.446659 |    370.485190 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 281 |   1006.301806 |    193.508651 | NA                                                                                                                                                                              |
| 282 |    865.984227 |    173.200249 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                        |
| 283 |    347.900215 |      4.255297 | Tasman Dixon                                                                                                                                                                    |
| 284 |    560.838481 |    395.793697 | Rafael Maia                                                                                                                                                                     |
| 285 |    353.071590 |    427.441550 | NA                                                                                                                                                                              |
| 286 |    762.153029 |    157.829847 | Elisabeth Östman                                                                                                                                                                |
| 287 |    419.350844 |    255.141860 | Felix Vaux                                                                                                                                                                      |
| 288 |   1007.196074 |    577.550939 | Melissa Broussard                                                                                                                                                               |
| 289 |     27.885919 |    585.274052 | Margot Michaud                                                                                                                                                                  |
| 290 |     50.940717 |    448.279417 | Gareth Monger                                                                                                                                                                   |
| 291 |    502.336549 |    636.530399 | Margot Michaud                                                                                                                                                                  |
| 292 |    324.143770 |    448.311127 | Jack Mayer Wood                                                                                                                                                                 |
| 293 |    116.300424 |    213.561528 | Scott Hartman                                                                                                                                                                   |
| 294 |    985.738699 |    495.250654 | Zimices                                                                                                                                                                         |
| 295 |    896.127699 |     77.899922 | NA                                                                                                                                                                              |
| 296 |    515.677550 |    786.112431 | Lily Hughes                                                                                                                                                                     |
| 297 |    167.317585 |    308.247109 | Anthony Caravaggi                                                                                                                                                               |
| 298 |    806.705010 |     83.028683 | Marie Russell                                                                                                                                                                   |
| 299 |    394.922485 |    469.831456 | Sarah Werning                                                                                                                                                                   |
| 300 |    590.170020 |    479.018728 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                                 |
| 301 |    671.000466 |    573.115449 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 302 |     96.708808 |    698.013800 | Jagged Fang Designs                                                                                                                                                             |
| 303 |    422.917254 |    398.277209 | Gareth Monger                                                                                                                                                                   |
| 304 |     15.005893 |    729.262914 | Ferran Sayol                                                                                                                                                                    |
| 305 |    434.701193 |     41.836153 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 306 |    975.608533 |     76.255564 | Chris huh                                                                                                                                                                       |
| 307 |     52.183817 |    238.911979 | Manabu Bessho-Uehara                                                                                                                                                            |
| 308 |     29.642940 |    312.857148 | Neil Kelley                                                                                                                                                                     |
| 309 |    311.133133 |     65.087518 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 310 |    753.178105 |    585.063746 | M. A. Broussard                                                                                                                                                                 |
| 311 |    600.476734 |     23.966779 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 312 |    619.339236 |    269.161904 | Ferran Sayol                                                                                                                                                                    |
| 313 |    962.515869 |    629.406907 | FunkMonk                                                                                                                                                                        |
| 314 |     77.891424 |    448.650635 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                                   |
| 315 |    390.873898 |    106.643299 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 316 |    632.281180 |    465.596785 | NA                                                                                                                                                                              |
| 317 |    896.604468 |    383.579652 | Jon M Laurent                                                                                                                                                                   |
| 318 |    562.813598 |    726.876190 | Scott Hartman                                                                                                                                                                   |
| 319 |    260.719658 |    733.983023 | Emily Willoughby                                                                                                                                                                |
| 320 |    286.112236 |    568.043319 | Gareth Monger                                                                                                                                                                   |
| 321 |    698.031006 |    791.942701 | Kent Sorgon                                                                                                                                                                     |
| 322 |    582.581306 |    153.663568 | Jagged Fang Designs                                                                                                                                                             |
| 323 |    122.574259 |    789.494153 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                          |
| 324 |    679.482882 |    666.889815 | Lukasiniho                                                                                                                                                                      |
| 325 |    497.301986 |    693.511787 | Ferran Sayol                                                                                                                                                                    |
| 326 |    133.146620 |    379.490291 | Jagged Fang Designs                                                                                                                                                             |
| 327 |    410.441966 |    460.382123 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                                  |
| 328 |    311.417753 |    741.089064 | Mariana Ruiz Villarreal                                                                                                                                                         |
| 329 |    608.982225 |    605.180170 | Scott Hartman                                                                                                                                                                   |
| 330 |    424.706285 |    591.968395 | Oliver Griffith                                                                                                                                                                 |
| 331 |    965.276020 |    267.524056 | Noah Schlottman                                                                                                                                                                 |
| 332 |    939.695147 |    455.135514 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 333 |    762.521130 |    762.588536 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                      |
| 334 |    681.957450 |    792.079453 | Mathieu Pélissié                                                                                                                                                                |
| 335 |    580.866153 |    687.132556 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                              |
| 336 |    876.716565 |     70.011642 | Steven Traver                                                                                                                                                                   |
| 337 |     40.193693 |    261.946063 | T. Michael Keesey                                                                                                                                                               |
| 338 |    969.510547 |    478.376257 | Zimices                                                                                                                                                                         |
| 339 |    845.686417 |    258.938193 | Margot Michaud                                                                                                                                                                  |
| 340 |    925.564201 |    598.296783 | Margot Michaud                                                                                                                                                                  |
| 341 |    643.292984 |    118.397125 | NA                                                                                                                                                                              |
| 342 |    306.945845 |    503.609934 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 343 |    441.890958 |    138.806241 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 344 |    930.868874 |    383.390807 | Matt Crook                                                                                                                                                                      |
| 345 |    158.569609 |    544.207725 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 346 |    647.401074 |    560.929349 | Matt Crook                                                                                                                                                                      |
| 347 |    614.558544 |    454.392362 | Scott Hartman                                                                                                                                                                   |
| 348 |    615.463159 |    528.221574 | Margot Michaud                                                                                                                                                                  |
| 349 |    601.905233 |    567.839853 | Tasman Dixon                                                                                                                                                                    |
| 350 |    441.459201 |    246.894630 | Harold N Eyster                                                                                                                                                                 |
| 351 |    127.742969 |    281.030359 | Gareth Monger                                                                                                                                                                   |
| 352 |    202.519432 |    492.517212 | Katie S. Collins                                                                                                                                                                |
| 353 |    286.819142 |    162.379373 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 354 |    421.555970 |    792.435177 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 355 |    722.208335 |    507.296102 | Rebecca Groom                                                                                                                                                                   |
| 356 |    277.533922 |    409.363889 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 357 |    217.281238 |    744.021737 | Dean Schnabel                                                                                                                                                                   |
| 358 |    550.055799 |    320.290424 | Scott Hartman                                                                                                                                                                   |
| 359 |    301.099163 |    100.859512 | FunkMonk                                                                                                                                                                        |
| 360 |     85.322777 |    418.431467 | Ferran Sayol                                                                                                                                                                    |
| 361 |    913.683380 |     87.518540 | Chloé Schmidt                                                                                                                                                                   |
| 362 |    885.039332 |    685.594897 | Matt Crook                                                                                                                                                                      |
| 363 |    445.122719 |     55.900227 | Margot Michaud                                                                                                                                                                  |
| 364 |     82.242968 |    697.991613 | Birgit Lang                                                                                                                                                                     |
| 365 |    809.000264 |     54.337192 | Matt Martyniuk                                                                                                                                                                  |
| 366 |    161.829258 |    519.010141 | Steven Traver                                                                                                                                                                   |
| 367 |    278.314030 |    653.572540 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 368 |    699.012433 |     16.982468 | NA                                                                                                                                                                              |
| 369 |    585.064390 |    531.199867 | Tasman Dixon                                                                                                                                                                    |
| 370 |    543.515862 |    393.207997 | Felix Vaux                                                                                                                                                                      |
| 371 |    261.034534 |    400.615792 | Ignacio Contreras                                                                                                                                                               |
| 372 |    736.890250 |    178.863456 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                       |
| 373 |     76.887823 |    676.980131 | Rebecca Groom                                                                                                                                                                   |
| 374 |     10.075084 |    556.726155 | NA                                                                                                                                                                              |
| 375 |     10.416462 |    688.622858 | Zimices                                                                                                                                                                         |
| 376 |    148.265744 |    569.738661 | Matt Crook                                                                                                                                                                      |
| 377 |   1001.261481 |    160.844040 | Gareth Monger                                                                                                                                                                   |
| 378 |    327.651911 |    167.183128 | Diana Pomeroy                                                                                                                                                                   |
| 379 |    447.552219 |     75.497352 | Maija Karala                                                                                                                                                                    |
| 380 |    131.738777 |    151.493089 | S.Martini                                                                                                                                                                       |
| 381 |    106.938864 |    619.861859 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 382 |    766.021852 |    565.285092 | Arthur S. Brum                                                                                                                                                                  |
| 383 |    524.803045 |    720.191998 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                              |
| 384 |    254.660422 |    353.750238 | L. Shyamal                                                                                                                                                                      |
| 385 |     19.676116 |     25.629639 | Iain Reid                                                                                                                                                                       |
| 386 |    431.610372 |    271.361875 | Carlos Cano-Barbacil                                                                                                                                                            |
| 387 |    182.670862 |     25.992344 | Jaime Headden                                                                                                                                                                   |
| 388 |     19.758985 |    236.604710 | Matt Celeskey                                                                                                                                                                   |
| 389 |    144.038499 |    398.352014 | Matt Crook                                                                                                                                                                      |
| 390 |    125.367825 |    353.571637 | Richard J. Harris                                                                                                                                                               |
| 391 |    553.165607 |    487.533369 | Gareth Monger                                                                                                                                                                   |
| 392 |    500.206730 |    786.361583 | Jagged Fang Designs                                                                                                                                                             |
| 393 |    738.196871 |    162.127453 | S.Martini                                                                                                                                                                       |
| 394 |    458.218630 |    557.492174 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                       |
| 395 |    343.212226 |    769.106682 | Birgit Lang                                                                                                                                                                     |
| 396 |    135.673458 |      8.642384 | Gareth Monger                                                                                                                                                                   |
| 397 |    668.998477 |     64.212145 | Margot Michaud                                                                                                                                                                  |
| 398 |    692.898714 |    574.793527 | T. Michael Keesey                                                                                                                                                               |
| 399 |    489.204954 |    737.087502 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                          |
| 400 |    678.919514 |    128.738955 | Jagged Fang Designs                                                                                                                                                             |
| 401 |   1012.422416 |     51.444428 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 402 |    325.712311 |    367.192647 | Owen Jones                                                                                                                                                                      |
| 403 |    451.792901 |    254.098805 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 404 |    881.518776 |    593.806972 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                                 |
| 405 |     11.821537 |    188.442974 | NA                                                                                                                                                                              |
| 406 |    775.860199 |    463.573605 | Felix Vaux                                                                                                                                                                      |
| 407 |    454.690371 |    410.977371 | Chris huh                                                                                                                                                                       |
| 408 |    546.015729 |    303.232358 | Steven Traver                                                                                                                                                                   |
| 409 |    742.080362 |    653.906294 | François Michonneau                                                                                                                                                             |
| 410 |    167.652356 |    558.387529 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 411 |    750.643301 |    306.793843 | Tasman Dixon                                                                                                                                                                    |
| 412 |    358.995706 |    674.286680 | Zimices                                                                                                                                                                         |
| 413 |    582.664291 |    670.314591 | L. Shyamal                                                                                                                                                                      |
| 414 |    415.655325 |     39.509010 | Anthony Caravaggi                                                                                                                                                               |
| 415 |    783.825496 |    568.323521 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                           |
| 416 |    182.489080 |    728.957526 | Michael Scroggie                                                                                                                                                                |
| 417 |    963.108181 |    466.566853 | Steven Blackwood                                                                                                                                                                |
| 418 |    504.784908 |    188.571266 | Margot Michaud                                                                                                                                                                  |
| 419 |    988.324973 |    421.641017 | Zimices                                                                                                                                                                         |
| 420 |    702.625750 |    571.339636 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
| 421 |   1003.327949 |    545.100053 | T. Michael Keesey                                                                                                                                                               |
| 422 |    342.064846 |     89.206103 | Renato Santos                                                                                                                                                                   |
| 423 |    920.011422 |     30.536392 | Zimices                                                                                                                                                                         |
| 424 |    294.999485 |    238.083410 | Margot Michaud                                                                                                                                                                  |
| 425 |    415.276956 |    579.103028 | Tasman Dixon                                                                                                                                                                    |
| 426 |    700.416476 |    767.231186 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 427 |    769.044833 |    502.154749 | Markus A. Grohme                                                                                                                                                                |
| 428 |    959.646455 |     71.153617 | Matt Crook                                                                                                                                                                      |
| 429 |    733.190814 |    451.128171 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 430 |     50.495487 |    475.595011 | Matt Crook                                                                                                                                                                      |
| 431 |    429.491418 |    606.419220 | NA                                                                                                                                                                              |
| 432 |     52.222436 |     17.456612 | NA                                                                                                                                                                              |
| 433 |    262.309224 |    333.698719 | NA                                                                                                                                                                              |
| 434 |    791.201586 |    745.505198 | Ferran Sayol                                                                                                                                                                    |
| 435 |    636.009685 |    747.572364 | Emily Willoughby                                                                                                                                                                |
| 436 |    289.656677 |    780.851321 | Steven Traver                                                                                                                                                                   |
| 437 |    529.637191 |    502.965682 | Steven Traver                                                                                                                                                                   |
| 438 |    753.377298 |    319.219187 | Julio Garza                                                                                                                                                                     |
| 439 |    694.284036 |    774.889073 | Steven Traver                                                                                                                                                                   |
| 440 |    433.629002 |    346.653031 | Matt Crook                                                                                                                                                                      |
| 441 |    805.619619 |    543.274405 | Caleb M. Brown                                                                                                                                                                  |
| 442 |    332.157169 |    513.268052 | Steven Traver                                                                                                                                                                   |
| 443 |    502.871234 |    730.685761 | T. Michael Keesey                                                                                                                                                               |
| 444 |    207.019301 |    258.606629 | Steven Coombs                                                                                                                                                                   |
| 445 |    226.567105 |    322.331101 | (after Spotila 2004)                                                                                                                                                            |
| 446 |    498.597134 |    340.300820 | Matt Crook                                                                                                                                                                      |
| 447 |   1016.260243 |    352.202179 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 448 |    243.198140 |    791.958965 | Zimices                                                                                                                                                                         |
| 449 |    956.401029 |    403.729766 | Scott Hartman                                                                                                                                                                   |
| 450 |    471.193813 |    310.472278 | T. Michael Keesey                                                                                                                                                               |
| 451 |    557.782052 |    510.574015 | Mathieu Pélissié                                                                                                                                                                |
| 452 |    299.545199 |    514.900308 | Ingo Braasch                                                                                                                                                                    |
| 453 |    952.786257 |    202.111282 | Ferran Sayol                                                                                                                                                                    |
| 454 |     32.273038 |    148.571272 | Sarah Werning                                                                                                                                                                   |
| 455 |    964.138557 |    178.935421 | Steven Traver                                                                                                                                                                   |
| 456 |    255.404450 |    622.941661 | Tasman Dixon                                                                                                                                                                    |
| 457 |     88.146674 |    596.026874 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 458 |    221.358376 |    688.301177 | Ferran Sayol                                                                                                                                                                    |
| 459 |     19.707151 |    318.917447 | Zimices                                                                                                                                                                         |
| 460 |    120.802163 |    529.971724 | Scott Hartman                                                                                                                                                                   |
| 461 |    108.008263 |    387.079585 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                        |
| 462 |    957.741236 |    606.393281 | Ferran Sayol                                                                                                                                                                    |
| 463 |    256.413504 |    672.551308 | Margot Michaud                                                                                                                                                                  |
| 464 |    688.168318 |    749.199363 | Margot Michaud                                                                                                                                                                  |
| 465 |    432.393409 |    221.479515 | Juan Carlos Jerí                                                                                                                                                                |
| 466 |    103.795511 |    297.658674 | Zimices                                                                                                                                                                         |
| 467 |    322.584618 |    723.778284 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                              |
| 468 |    987.198691 |    221.341193 | Markus A. Grohme                                                                                                                                                                |
| 469 |    752.507489 |    539.031469 | NA                                                                                                                                                                              |
| 470 |    994.152987 |     93.900415 | Noah Schlottman                                                                                                                                                                 |
| 471 |   1014.377343 |    300.682894 | Gareth Monger                                                                                                                                                                   |
| 472 |    635.674306 |    765.834617 | T. Michael Keesey                                                                                                                                                               |
| 473 |    699.417009 |    287.373965 | Christoph Schomburg                                                                                                                                                             |
| 474 |    854.741993 |     76.045431 | Margot Michaud                                                                                                                                                                  |
| 475 |    980.629677 |    552.618449 | Cagri Cevrim                                                                                                                                                                    |
| 476 |    612.699905 |    565.845385 | NA                                                                                                                                                                              |
| 477 |    656.716909 |     27.971712 | Jack Mayer Wood                                                                                                                                                                 |
| 478 |    994.360605 |    512.313201 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                               |
| 479 |    152.401313 |      9.550917 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                               |
| 480 |    922.782150 |    264.808314 | Chris huh                                                                                                                                                                       |
| 481 |   1006.194345 |    107.430500 | Michelle Site                                                                                                                                                                   |
| 482 |     32.462037 |    477.380537 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                  |
| 483 |    709.950793 |    668.818365 | Melissa Broussard                                                                                                                                                               |
| 484 |    494.103584 |    410.669333 | T. Michael Keesey                                                                                                                                                               |
| 485 |    432.154590 |    652.888132 | T. Michael Keesey                                                                                                                                                               |
| 486 |     74.028897 |    292.366339 | Gareth Monger                                                                                                                                                                   |
| 487 |    144.934890 |    126.076626 | Sarah Werning                                                                                                                                                                   |
| 488 |    249.662480 |    582.733158 | Gareth Monger                                                                                                                                                                   |
| 489 |     54.798913 |    157.048298 | Michael Scroggie                                                                                                                                                                |
| 490 |     32.786591 |    500.666626 | Mathieu Basille                                                                                                                                                                 |
| 491 |    652.774976 |     80.772571 | Michelle Site                                                                                                                                                                   |
| 492 |    574.893316 |     56.573567 | Chris Hay                                                                                                                                                                       |
| 493 |    795.256102 |     94.575786 | Dean Schnabel                                                                                                                                                                   |
| 494 |    548.209934 |    412.307858 | NA                                                                                                                                                                              |
| 495 |    501.844236 |     60.142227 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                           |
| 496 |    159.619155 |    572.756000 | Matt Crook                                                                                                                                                                      |
| 497 |    932.980831 |    720.425871 | NA                                                                                                                                                                              |
| 498 |    350.579036 |    784.284510 | Margot Michaud                                                                                                                                                                  |
| 499 |    307.700576 |    530.227395 | Matthew E. Clapham                                                                                                                                                              |
| 500 |    581.418887 |    179.275001 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 501 |    946.292366 |    757.838086 | Steven Traver                                                                                                                                                                   |
| 502 |    712.780587 |    316.943929 | Carlos Cano-Barbacil                                                                                                                                                            |
| 503 |    946.754365 |    220.192757 | Matt Martyniuk                                                                                                                                                                  |
| 504 |    595.039404 |    599.138067 | Sarah Werning                                                                                                                                                                   |
| 505 |    873.244985 |    368.003212 | Gareth Monger                                                                                                                                                                   |
| 506 |    427.061837 |    747.558447 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 507 |     39.456993 |    239.339089 | Matt Crook                                                                                                                                                                      |
| 508 |    775.360236 |    765.170730 | Tracy A. Heath                                                                                                                                                                  |
| 509 |    285.863712 |    447.022048 | Zimices                                                                                                                                                                         |
| 510 |    584.971444 |    193.339320 | Ferran Sayol                                                                                                                                                                    |
| 511 |     60.475458 |    580.299173 | Margot Michaud                                                                                                                                                                  |
| 512 |    428.172848 |    285.523399 | Matt Crook                                                                                                                                                                      |
| 513 |    304.338664 |     88.991130 | Danielle Alba                                                                                                                                                                   |
| 514 |    181.440658 |    538.924858 | Zimices                                                                                                                                                                         |
| 515 |    921.504516 |    762.489503 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 516 |    990.170456 |    563.180116 | Noah Schlottman                                                                                                                                                                 |
| 517 |    339.803798 |    229.420260 | Margot Michaud                                                                                                                                                                  |
| 518 |    859.389813 |    709.302177 | Todd Marshall, vectorized by Zimices                                                                                                                                            |
| 519 |    896.327570 |     29.608427 | Ferran Sayol                                                                                                                                                                    |
| 520 |    964.682761 |    519.395439 | Birgit Lang                                                                                                                                                                     |
| 521 |    286.753746 |    222.963108 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                              |
| 522 |    498.501027 |    439.144289 | Kamil S. Jaron                                                                                                                                                                  |
| 523 |    405.309322 |    309.920787 | Steven Traver                                                                                                                                                                   |
| 524 |    984.445392 |    429.995763 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 525 |      7.598435 |    308.532642 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 526 |    507.391175 |     80.890174 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                                    |
| 527 |    387.740915 |    272.491287 | Kai R. Caspar                                                                                                                                                                   |
| 528 |    303.457813 |    496.998365 | Arthur S. Brum                                                                                                                                                                  |
| 529 |    741.309221 |    518.662936 | Beth Reinke                                                                                                                                                                     |
| 530 |    911.093664 |    623.843450 | Zimices                                                                                                                                                                         |
| 531 |    691.816392 |    269.650865 | Margot Michaud                                                                                                                                                                  |
| 532 |    705.942189 |    339.529316 | Agnello Picorelli                                                                                                                                                               |
| 533 |    519.126342 |    576.160110 | Ingo Braasch                                                                                                                                                                    |
| 534 |    632.260586 |    347.153106 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 535 |   1019.123818 |    181.514002 | Konsta Happonen                                                                                                                                                                 |
| 536 |    681.919586 |    216.186212 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                    |
| 537 |    343.148448 |     38.872277 | T. Michael Keesey                                                                                                                                                               |
| 538 |    353.636939 |    582.682153 | Matt Crook                                                                                                                                                                      |
| 539 |    941.756994 |    265.108549 | NA                                                                                                                                                                              |
| 540 |     19.578639 |    761.863749 | Scott Hartman                                                                                                                                                                   |
| 541 |    422.576983 |    174.474505 | Zimices                                                                                                                                                                         |
| 542 |     79.945685 |    603.775549 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 543 |    445.537720 |    236.470638 | Jagged Fang Designs                                                                                                                                                             |
| 544 |    353.607314 |    324.648553 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 545 |     80.961271 |    669.244017 | Felix Vaux and Steven A. Trewick                                                                                                                                                |
| 546 |    339.838556 |    758.404780 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                         |
| 547 |    903.154093 |    574.205936 | NA                                                                                                                                                                              |
| 548 |    597.577845 |    541.806048 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 549 |    941.241798 |    476.417913 | Matt Crook                                                                                                                                                                      |
| 550 |    955.910515 |    214.714469 | Ignacio Contreras                                                                                                                                                               |
| 551 |    404.885944 |    349.683256 | Matt Crook                                                                                                                                                                      |
| 552 |    311.470637 |    160.803183 | Zimices                                                                                                                                                                         |
| 553 |    676.053620 |    487.829396 | Roberto Díaz Sibaja                                                                                                                                                             |
| 554 |    682.270574 |     21.459420 | Iain Reid                                                                                                                                                                       |
| 555 |    513.555612 |    432.523813 | Jaime Headden                                                                                                                                                                   |
| 556 |    213.863690 |     72.784466 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 557 |    165.788620 |    389.633345 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                    |
| 558 |    885.774248 |    299.483709 | Matt Crook                                                                                                                                                                      |
| 559 |    561.929115 |    265.111987 | T. Michael Keesey                                                                                                                                                               |
| 560 |    472.024179 |    264.552490 | Chris huh                                                                                                                                                                       |
| 561 |    721.349401 |    600.124385 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                 |
| 562 |    427.800078 |     84.449658 | T. Michael Keesey                                                                                                                                                               |
| 563 |    863.911684 |    288.450696 | Zimices                                                                                                                                                                         |
| 564 |    667.287699 |    110.498001 | Margot Michaud                                                                                                                                                                  |
| 565 |    407.283600 |    277.403756 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                       |
| 566 |    462.917822 |    138.333996 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 567 |    657.152942 |    666.763567 | Margot Michaud                                                                                                                                                                  |
| 568 |    831.990075 |    682.748057 | T. Michael Keesey                                                                                                                                                               |
| 569 |    850.262512 |    114.792507 | Cristina Guijarro                                                                                                                                                               |
| 570 |    970.676227 |    505.382994 | Raven Amos                                                                                                                                                                      |
| 571 |    375.704809 |    110.538449 | Zimices                                                                                                                                                                         |
| 572 |    326.501682 |     86.954952 | NA                                                                                                                                                                              |
| 573 |    575.042720 |    395.153135 | NA                                                                                                                                                                              |
| 574 |    719.688737 |    223.219122 | Pedro de Siracusa                                                                                                                                                               |
| 575 |    296.531462 |    182.422546 | FJDegrange                                                                                                                                                                      |
| 576 |    996.933663 |    783.038206 | Margot Michaud                                                                                                                                                                  |
| 577 |    841.860114 |    713.177447 | Jiekun He                                                                                                                                                                       |
| 578 |    246.174290 |    107.701398 | Birgit Lang                                                                                                                                                                     |
| 579 |     99.641744 |    519.886075 | Scott Hartman                                                                                                                                                                   |
| 580 |    336.213545 |    178.303161 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                               |
| 581 |    297.705554 |    203.256205 | Matt Crook                                                                                                                                                                      |
| 582 |    755.519003 |    484.667234 | Todd Marshall, vectorized by Zimices                                                                                                                                            |
| 583 |    462.951751 |    587.443247 | Zimices                                                                                                                                                                         |
| 584 |    333.123443 |    347.352354 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                               |
| 585 |    470.078743 |     73.501881 | Melissa Broussard                                                                                                                                                               |
| 586 |     11.488082 |    675.309337 | Joanna Wolfe                                                                                                                                                                    |
| 587 |     63.364931 |    526.724009 | Steven Traver                                                                                                                                                                   |
| 588 |    609.066297 |    472.804789 | Chris huh                                                                                                                                                                       |
| 589 |    922.799644 |    108.980107 | Ferran Sayol                                                                                                                                                                    |
| 590 |    391.128976 |    768.846788 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
| 591 |    107.054020 |    432.628757 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 592 |    542.182381 |    269.386090 | Steven Traver                                                                                                                                                                   |
| 593 |    448.065588 |    170.131435 | Christine Axon                                                                                                                                                                  |
| 594 |    361.290901 |     98.853808 | Zimices                                                                                                                                                                         |
| 595 |    874.962929 |    305.243497 | Zimices                                                                                                                                                                         |
| 596 |     65.756285 |    308.335860 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                           |
| 597 |    752.852361 |    696.737451 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                              |
| 598 |    860.916497 |    269.609990 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 599 |    349.981532 |    531.102262 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 600 |     25.963845 |    792.659847 | Zimices                                                                                                                                                                         |
| 601 |    328.667920 |    438.829161 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 602 |    474.822475 |    454.969566 | Michael Scroggie                                                                                                                                                                |
| 603 |    603.422125 |      7.082886 | Margot Michaud                                                                                                                                                                  |
| 604 |    957.559908 |    228.408667 | Jagged Fang Designs                                                                                                                                                             |
| 605 |    739.830918 |    190.315527 | Scott Hartman                                                                                                                                                                   |
| 606 |    803.745021 |    753.728483 | T. Michael Keesey                                                                                                                                                               |
| 607 |    945.082376 |     32.462524 | Kai R. Caspar                                                                                                                                                                   |
| 608 |    902.127458 |     65.068871 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 609 |    720.858469 |    202.215706 | Ignacio Contreras                                                                                                                                                               |
| 610 |    148.538233 |    450.898480 | T. Michael Keesey                                                                                                                                                               |
| 611 |    376.947054 |    680.499448 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 612 |    387.641398 |    287.548368 | Matt Crook                                                                                                                                                                      |
| 613 |    112.764150 |    700.458966 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                    |
| 614 |    119.731196 |      5.454003 | Iain Reid                                                                                                                                                                       |
| 615 |    350.921877 |    245.589087 | Robert Gay                                                                                                                                                                      |
| 616 |    332.516979 |    388.554821 | Matt Crook                                                                                                                                                                      |
| 617 |    582.595746 |    124.358155 | Jessica Anne Miller                                                                                                                                                             |
| 618 |    740.660487 |    336.130544 | Scott Hartman                                                                                                                                                                   |
| 619 |    915.449631 |    168.067115 | Scott Hartman                                                                                                                                                                   |
| 620 |    736.545791 |     17.022464 | Tasman Dixon                                                                                                                                                                    |
| 621 |    202.095262 |    724.239256 | Tasman Dixon                                                                                                                                                                    |
| 622 |     97.237227 |    599.071217 | V. Deepak                                                                                                                                                                       |
| 623 |    176.626781 |    775.029178 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 624 |    962.576999 |    550.162113 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                |
| 625 |    232.384110 |    529.925346 | Chris huh                                                                                                                                                                       |
| 626 |    983.954086 |    484.917902 | Mason McNair                                                                                                                                                                    |
| 627 |     49.608941 |    325.266448 | Samanta Orellana                                                                                                                                                                |
| 628 |    401.169630 |    337.247073 | Steven Traver                                                                                                                                                                   |
| 629 |    274.958977 |    345.199760 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 630 |    835.816544 |    461.253354 | Alexandre Vong                                                                                                                                                                  |
| 631 |    396.307609 |     91.122281 | Matt Crook                                                                                                                                                                      |
| 632 |    994.810764 |    531.627897 | M Hutchinson                                                                                                                                                                    |
| 633 |    843.644196 |    297.520110 | NA                                                                                                                                                                              |
| 634 |    800.886710 |    769.104650 | Maija Karala                                                                                                                                                                    |
| 635 |    530.775976 |    400.189090 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 636 |    278.606464 |    141.473630 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 637 |    307.703319 |    182.056346 | Bruno C. Vellutini                                                                                                                                                              |
| 638 |    220.292233 |    488.129763 | NA                                                                                                                                                                              |
| 639 |    992.759043 |    552.036601 | Matt Crook                                                                                                                                                                      |
| 640 |    306.349759 |    253.799928 | Maxime Dahirel                                                                                                                                                                  |
| 641 |    487.035699 |    224.734004 | Matt Martyniuk                                                                                                                                                                  |
| 642 |     57.196508 |    591.574515 | Maxime Dahirel                                                                                                                                                                  |
| 643 |      8.376366 |    702.819541 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
| 644 |    398.202824 |     43.460441 | Shyamal                                                                                                                                                                         |
| 645 |    679.357269 |    152.353863 | FunkMonk                                                                                                                                                                        |
| 646 |    155.504605 |    737.458946 | Tony Ayling                                                                                                                                                                     |
| 647 |   1006.291805 |    130.284707 | FunkMonk                                                                                                                                                                        |
| 648 |    892.174615 |    184.007398 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                                 |
| 649 |    425.452007 |     48.853123 | Ferran Sayol                                                                                                                                                                    |
| 650 |     25.728909 |    193.459829 | Chris Hay                                                                                                                                                                       |
| 651 |    900.646860 |    435.876064 | Servien (vectorized by T. Michael Keesey)                                                                                                                                       |
| 652 |    927.790243 |    612.825957 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                 |
| 653 |    920.924428 |    770.604427 | Steven Traver                                                                                                                                                                   |
| 654 |     20.456608 |    333.931829 | Zimices                                                                                                                                                                         |
| 655 |    662.558507 |    122.299835 | Jagged Fang Designs                                                                                                                                                             |
| 656 |    470.016597 |    175.555434 | Lukasiniho                                                                                                                                                                      |
| 657 |    823.416798 |    227.337159 | Shyamal                                                                                                                                                                         |
| 658 |    197.129692 |    536.669626 | Terpsichores                                                                                                                                                                    |
| 659 |    561.953389 |    279.682503 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 660 |    116.823092 |     13.975006 | Zimices                                                                                                                                                                         |
| 661 |    280.815360 |     81.735332 | Julio Garza                                                                                                                                                                     |
| 662 |    916.765576 |    734.033445 | Zimices                                                                                                                                                                         |
| 663 |     51.476078 |    776.807789 | Matt Crook                                                                                                                                                                      |
| 664 |    118.725701 |    589.931078 | Jaime Headden                                                                                                                                                                   |
| 665 |    669.034910 |    252.882320 | Zimices                                                                                                                                                                         |
| 666 |    681.644878 |    771.200424 | DW Bapst (modified from Bulman, 1970)                                                                                                                                           |
| 667 |    978.120292 |    514.684335 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                       |
| 668 |    871.738887 |    581.810065 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 669 |    773.994258 |    341.196088 | Mathilde Cordellier                                                                                                                                                             |
| 670 |    482.616219 |    259.677107 | T. Michael Keesey                                                                                                                                                               |
| 671 |    156.976170 |     26.674154 | Fernando Carezzano                                                                                                                                                              |
| 672 |    375.321842 |    450.242712 | Jagged Fang Designs                                                                                                                                                             |
| 673 |    511.536818 |    588.563974 | Ferran Sayol                                                                                                                                                                    |
| 674 |    458.216148 |    543.660435 | T. Michael Keesey                                                                                                                                                               |
| 675 |    206.706522 |    696.122136 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 676 |     89.502099 |    712.966825 | Pete Buchholz                                                                                                                                                                   |
| 677 |    681.372672 |    175.772567 | Margot Michaud                                                                                                                                                                  |
| 678 |    243.476739 |    627.313188 | Chuanixn Yu                                                                                                                                                                     |
| 679 |    463.674211 |    358.308213 | FunkMonk                                                                                                                                                                        |
| 680 |    888.362773 |    198.809813 | Chris huh                                                                                                                                                                       |
| 681 |    286.987211 |    641.731319 | Matt Crook                                                                                                                                                                      |
| 682 |    106.813069 |    669.814514 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                                |
| 683 |    873.377150 |    772.391945 | Matt Crook                                                                                                                                                                      |
| 684 |    355.737135 |    267.627372 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 685 |     23.941336 |    704.780363 | Steven Traver                                                                                                                                                                   |
| 686 |    528.994464 |    678.477993 | Scott Reid                                                                                                                                                                      |
| 687 |    689.250811 |    132.856191 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                |
| 688 |    624.992499 |     10.260125 | Zimices                                                                                                                                                                         |
| 689 |     65.970183 |    486.622145 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                                 |
| 690 |    500.305369 |    512.101655 | NA                                                                                                                                                                              |
| 691 |     79.937671 |     99.428181 | Jagged Fang Designs                                                                                                                                                             |
| 692 |    317.947819 |    350.730369 | Manabu Bessho-Uehara                                                                                                                                                            |
| 693 |    876.926608 |    709.531247 | Roberto Díaz Sibaja                                                                                                                                                             |
| 694 |    777.920635 |    478.174664 | Inessa Voet                                                                                                                                                                     |
| 695 |    324.237929 |    528.805049 | Matt Crook                                                                                                                                                                      |
| 696 |    482.922479 |    440.624879 | Christoph Schomburg                                                                                                                                                             |
| 697 |    230.828536 |    367.928018 | Andrew A. Farke                                                                                                                                                                 |
| 698 |    960.563162 |    380.800574 | Maija Karala                                                                                                                                                                    |
| 699 |    832.753276 |    269.150256 | Chris huh                                                                                                                                                                       |
| 700 |    432.293205 |    153.343226 | Gareth Monger                                                                                                                                                                   |
| 701 |    214.379882 |    569.310438 | Andrew A. Farke                                                                                                                                                                 |
| 702 |    327.301504 |    660.830335 | Margot Michaud                                                                                                                                                                  |
| 703 |    128.584195 |    302.093878 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 704 |    567.358421 |     39.008260 | NA                                                                                                                                                                              |
| 705 |    608.094567 |    481.841947 | Chuanixn Yu                                                                                                                                                                     |
| 706 |    323.567419 |    562.751400 | Tracy A. Heath                                                                                                                                                                  |
| 707 |    989.311084 |    395.087741 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 708 |    469.583069 |    719.903541 | Christine Axon                                                                                                                                                                  |
| 709 |    309.546941 |    331.463644 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 710 |    840.551059 |    198.565916 | Falconaumanni and T. Michael Keesey                                                                                                                                             |
| 711 |    354.974689 |    385.419272 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 712 |    806.335386 |    104.490703 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 713 |    657.407291 |    264.003469 | NA                                                                                                                                                                              |
| 714 |   1014.586308 |    518.586860 | Cathy                                                                                                                                                                           |
| 715 |    829.072053 |    222.454801 | Chris huh                                                                                                                                                                       |
| 716 |    759.030318 |    610.567549 | Gareth Monger                                                                                                                                                                   |
| 717 |    487.896511 |    765.705810 | Margot Michaud                                                                                                                                                                  |
| 718 |    993.698379 |    181.325379 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 719 |    589.151725 |    714.499310 | Cesar Julian                                                                                                                                                                    |
| 720 |   1016.237083 |    430.639173 | Matt Crook                                                                                                                                                                      |
| 721 |     87.834068 |    500.851619 | Andrew A. Farke                                                                                                                                                                 |
| 722 |    875.777637 |    348.171181 | Steven Traver                                                                                                                                                                   |
| 723 |    459.740352 |    578.094035 | Steven Traver                                                                                                                                                                   |
| 724 |    250.071706 |    364.157713 | Armin Reindl                                                                                                                                                                    |
| 725 |    115.758907 |    382.392362 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                                       |
| 726 |     20.523400 |    258.434845 | Sarah Werning                                                                                                                                                                   |
| 727 |     36.387668 |    325.496389 | Zimices                                                                                                                                                                         |
| 728 |     10.127646 |    267.620928 | Matt Crook                                                                                                                                                                      |
| 729 |    107.547644 |    453.896264 | Mason McNair                                                                                                                                                                    |
| 730 |    205.487885 |    135.694931 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 731 |    851.037872 |    245.287854 | Collin Gross                                                                                                                                                                    |
| 732 |    140.253000 |    219.679943 | Matt Crook                                                                                                                                                                      |
| 733 |    196.998619 |    778.648239 | Margot Michaud                                                                                                                                                                  |
| 734 |    649.799036 |    792.945427 | Eyal Bartov                                                                                                                                                                     |
| 735 |    263.042619 |    634.343254 | Zimices                                                                                                                                                                         |
| 736 |    606.590919 |    265.759939 | Margot Michaud                                                                                                                                                                  |
| 737 |    485.444186 |    782.521108 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 738 |    768.524835 |    611.798249 | Birgit Lang                                                                                                                                                                     |
| 739 |     70.071672 |    594.313970 | NA                                                                                                                                                                              |
| 740 |    991.543357 |    151.107641 | Michael Scroggie                                                                                                                                                                |
| 741 |    549.060563 |    293.305890 | Smokeybjb                                                                                                                                                                       |
| 742 |     86.248643 |      6.705957 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 743 |    231.755074 |    706.385511 | Emily Willoughby                                                                                                                                                                |
| 744 |    933.362550 |    229.877289 | Cesar Julian                                                                                                                                                                    |
| 745 |    586.060844 |    312.428402 | Ferran Sayol                                                                                                                                                                    |
| 746 |    555.278737 |    597.639810 | Jagged Fang Designs                                                                                                                                                             |
| 747 |    464.816465 |    276.497340 | Hans Hillewaert                                                                                                                                                                 |
| 748 |     62.833324 |    747.372568 | Matt Crook                                                                                                                                                                      |
| 749 |    533.933425 |    515.858605 | Matt Crook                                                                                                                                                                      |
| 750 |    283.067289 |    184.817479 | Marie Russell                                                                                                                                                                   |
| 751 |    997.586106 |    403.681692 | Margot Michaud                                                                                                                                                                  |
| 752 |    250.052020 |    456.341371 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                      |
| 753 |    516.698973 |    335.124588 | Maija Karala                                                                                                                                                                    |
| 754 |    303.472062 |    442.301936 | terngirl                                                                                                                                                                        |
| 755 |    890.166410 |    702.759858 | Katie S. Collins                                                                                                                                                                |
| 756 |    880.058001 |    585.460545 | Lauren Sumner-Rooney                                                                                                                                                            |
| 757 |    834.967702 |    349.401817 | Matt Crook                                                                                                                                                                      |
| 758 |     56.452979 |    787.589209 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                           |
| 759 |    692.538601 |    664.593068 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                                 |
| 760 |    872.478668 |    328.689479 | Cesar Julian                                                                                                                                                                    |
| 761 |    629.013598 |    566.363170 | Steven Traver                                                                                                                                                                   |
| 762 |    546.614655 |    132.543304 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                                      |
| 763 |    697.593893 |    258.326052 | Markus A. Grohme                                                                                                                                                                |
| 764 |    198.542027 |    793.640475 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 765 |    238.685881 |    573.018433 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                     |
| 766 |    625.736585 |    635.442541 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                       |
| 767 |    272.358065 |    783.479901 | Alexandre Vong                                                                                                                                                                  |
| 768 |    529.451903 |    208.082752 | Alexandre Vong                                                                                                                                                                  |
| 769 |     22.053226 |    742.850027 | Jimmy Bernot                                                                                                                                                                    |
| 770 |    808.267616 |    522.578580 | Margot Michaud                                                                                                                                                                  |
| 771 |    584.811902 |    494.827530 | Xavier Giroux-Bougard                                                                                                                                                           |
| 772 |     95.055780 |    507.579890 | Zimices                                                                                                                                                                         |
| 773 |    412.179990 |    721.344547 | Jakovche                                                                                                                                                                        |
| 774 |    208.035271 |     13.186966 | Kanchi Nanjo                                                                                                                                                                    |
| 775 |   1003.250790 |    217.828697 | Maija Karala                                                                                                                                                                    |
| 776 |    402.339063 |    602.589267 | Tasman Dixon                                                                                                                                                                    |
| 777 |    797.760361 |     65.130588 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 778 |   1014.811571 |     74.688665 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                                       |
| 779 |    791.091156 |    668.927363 | FunkMonk                                                                                                                                                                        |
| 780 |     95.147966 |    334.585202 | Gareth Monger                                                                                                                                                                   |
| 781 |    567.538870 |    530.238602 | Matt Crook                                                                                                                                                                      |
| 782 |    817.320697 |    264.508661 | Crystal Maier                                                                                                                                                                   |
| 783 |   1012.083220 |    117.063800 | NA                                                                                                                                                                              |
| 784 |     36.675503 |    481.883441 | Sean McCann                                                                                                                                                                     |
| 785 |    472.974370 |    734.613043 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                                  |
| 786 |    929.957569 |    496.721648 | Matt Crook                                                                                                                                                                      |
| 787 |     68.329227 |    688.313385 | Birgit Lang                                                                                                                                                                     |
| 788 |    996.374909 |    448.106827 | Juan Carlos Jerí                                                                                                                                                                |
| 789 |    614.097789 |    301.235085 | Ignacio Contreras                                                                                                                                                               |
| 790 |    250.889204 |    716.326465 | L. Shyamal                                                                                                                                                                      |
| 791 |    657.171787 |     97.194143 | Cristina Guijarro                                                                                                                                                               |
| 792 |    396.987141 |    697.353877 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                               |
| 793 |    386.043321 |    663.722277 | Tauana J. Cunha                                                                                                                                                                 |
| 794 |    117.241082 |    227.613777 | Matt Crook                                                                                                                                                                      |
| 795 |   1013.920117 |     26.613443 | T. Michael Keesey                                                                                                                                                               |
| 796 |    875.624747 |    455.184880 | Andrew A. Farke                                                                                                                                                                 |
| 797 |    347.226729 |    365.703135 | NA                                                                                                                                                                              |
| 798 |    801.532322 |    664.054857 | Tauana J. Cunha                                                                                                                                                                 |
| 799 |    966.891350 |    223.571182 | Tasman Dixon                                                                                                                                                                    |
| 800 |     43.802023 |     37.978449 | Jagged Fang Designs                                                                                                                                                             |
| 801 |    806.181480 |    223.475652 | NA                                                                                                                                                                              |
| 802 |    928.367660 |    270.718005 | Ferran Sayol                                                                                                                                                                    |
| 803 |    185.418373 |    135.151632 | Zimices                                                                                                                                                                         |
| 804 |    506.458913 |    216.208964 | Natalie Claunch                                                                                                                                                                 |
| 805 |    444.347911 |    712.851989 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 806 |    974.992659 |    782.251661 | T. Michael Keesey                                                                                                                                                               |
| 807 |     42.381543 |     29.623971 | Christoph Schomburg                                                                                                                                                             |
| 808 |    413.480396 |    164.953787 | Birgit Lang                                                                                                                                                                     |
| 809 |    549.117828 |     50.715656 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 810 |    414.909974 |    133.741847 | Jaime Headden                                                                                                                                                                   |
| 811 |    876.058458 |     85.697685 | Tasman Dixon                                                                                                                                                                    |
| 812 |    876.078482 |    317.985788 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                |
| 813 |    327.496018 |    713.729796 | Zimices                                                                                                                                                                         |
| 814 |    731.259177 |    645.059347 | Ferran Sayol                                                                                                                                                                    |
| 815 |    381.379497 |    654.757403 | Jagged Fang Designs                                                                                                                                                             |
| 816 |    693.807857 |    242.783994 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 817 |    587.728680 |    293.196091 | Burton Robert, USFWS                                                                                                                                                            |
| 818 |    306.169856 |    216.566340 | Margot Michaud                                                                                                                                                                  |
| 819 |    492.021705 |    312.718907 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                    |
| 820 |    660.540721 |    482.871009 | Birgit Lang                                                                                                                                                                     |
| 821 |    466.736674 |    153.767300 | Melissa Broussard                                                                                                                                                               |
| 822 |    814.720258 |     95.132683 | Zimices                                                                                                                                                                         |
| 823 |     66.166786 |    790.841231 | Jagged Fang Designs                                                                                                                                                             |
| 824 |     52.262655 |    147.195641 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                                       |
| 825 |    111.656046 |    151.178591 | Ferran Sayol                                                                                                                                                                    |
| 826 |    858.715603 |    201.217122 | Zimices                                                                                                                                                                         |
| 827 |    847.919590 |    323.105337 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
| 828 |    849.243454 |    651.079291 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 829 |    283.678651 |    507.986713 | Scott Hartman                                                                                                                                                                   |
| 830 |    186.982680 |    328.159012 | Mathew Wedel                                                                                                                                                                    |
| 831 |     10.780045 |    532.716451 | Matt Crook                                                                                                                                                                      |
| 832 |   1004.933260 |    289.623552 | Zimices                                                                                                                                                                         |
| 833 |    353.631878 |    441.529289 | Lukas Panzarin                                                                                                                                                                  |
| 834 |    918.571997 |    550.791261 | Xavier Giroux-Bougard                                                                                                                                                           |
| 835 |    414.628113 |    145.697704 | Jon M Laurent                                                                                                                                                                   |
| 836 |    980.000789 |    177.165350 | Margot Michaud                                                                                                                                                                  |
| 837 |    197.266670 |    445.884177 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                      |
| 838 |    269.199057 |    121.472760 | Terpsichores                                                                                                                                                                    |
| 839 |    518.686463 |    508.190299 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 840 |    940.901063 |    363.922272 | Scott Hartman                                                                                                                                                                   |
| 841 |    403.464566 |    750.507485 | Kai R. Caspar                                                                                                                                                                   |
| 842 |    630.612442 |      2.646052 | Gustav Mützel                                                                                                                                                                   |
| 843 |    299.871910 |    246.483249 | Matt Crook                                                                                                                                                                      |
| 844 |    742.700149 |    531.480097 | Christoph Schomburg                                                                                                                                                             |
| 845 |    861.481075 |    453.624727 | Margot Michaud                                                                                                                                                                  |
| 846 |    656.979976 |    771.134142 | T. Michael Keesey (after Tillyard)                                                                                                                                              |
| 847 |    417.413330 |    387.816264 | Chase Brownstein                                                                                                                                                                |
| 848 |    133.252996 |    786.309930 | NA                                                                                                                                                                              |
| 849 |    114.304503 |    399.905546 | Ignacio Contreras                                                                                                                                                               |
| 850 |    396.603073 |    585.747797 | T. Michael Keesey                                                                                                                                                               |
| 851 |   1016.572753 |    699.418935 | Ferran Sayol                                                                                                                                                                    |
| 852 |    127.368788 |    453.852276 | NA                                                                                                                                                                              |
| 853 |      1.818514 |    604.851273 | Michelle Site                                                                                                                                                                   |
| 854 |    604.661795 |    331.872826 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 855 |    496.309904 |     95.560841 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 856 |    487.592260 |    242.416261 | Craig Dylke                                                                                                                                                                     |
| 857 |    460.656536 |    246.335742 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 858 |    902.682031 |    221.811534 | Gareth Monger                                                                                                                                                                   |
| 859 |    198.358724 |    349.777588 | NA                                                                                                                                                                              |
| 860 |    971.766038 |     19.136727 | Maija Karala                                                                                                                                                                    |
| 861 |    847.932457 |    332.008485 | Tasman Dixon                                                                                                                                                                    |
| 862 |      8.087590 |    120.721902 | Matt Crook                                                                                                                                                                      |
| 863 |    820.022797 |    486.919435 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 864 |    434.819122 |    781.348095 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 865 |    553.916625 |    789.126256 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                                 |
| 866 |    570.439613 |    318.824884 | Chase Brownstein                                                                                                                                                                |
| 867 |    758.400008 |    341.708131 | Sharon Wegner-Larsen                                                                                                                                                            |
| 868 |    996.958078 |    283.461285 | Caleb M. Brown                                                                                                                                                                  |
| 869 |    961.917445 |    252.440064 | Chris huh                                                                                                                                                                       |
| 870 |     16.297993 |    106.592452 | Matt Crook                                                                                                                                                                      |
| 871 |     11.879973 |    582.236877 | Matt Crook                                                                                                                                                                      |
| 872 |    916.047615 |    356.886470 | (after Spotila 2004)                                                                                                                                                            |
| 873 |    383.740683 |    278.581437 | Caleb M. Brown                                                                                                                                                                  |
| 874 |    234.505197 |     52.617228 | Matt Crook                                                                                                                                                                      |
| 875 |    368.436665 |    686.049765 | Sean McCann                                                                                                                                                                     |
| 876 |    348.193491 |    202.654228 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 877 |    987.750422 |      9.221184 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 878 |    709.283488 |    216.387218 | FunkMonk                                                                                                                                                                        |
| 879 |    768.612642 |    327.768906 | Trond R. Oskars                                                                                                                                                                 |
| 880 |    583.750007 |    639.922549 | Sean McCann                                                                                                                                                                     |
| 881 |    599.126656 |    580.532594 | Roberto Díaz Sibaja                                                                                                                                                             |
| 882 |    945.112120 |    490.856718 | Chloé Schmidt                                                                                                                                                                   |
| 883 |    977.559449 |    541.960021 | Nobu Tamura                                                                                                                                                                     |
| 884 |    540.503066 |      5.779170 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 885 |    323.592927 |    105.319767 | Jessica Rick                                                                                                                                                                    |
| 886 |    982.974961 |    447.850178 | Zimices                                                                                                                                                                         |
| 887 |    776.010631 |    576.990804 | NA                                                                                                                                                                              |
| 888 |    247.187231 |    530.163242 | Chase Brownstein                                                                                                                                                                |
| 889 |     76.295585 |    474.073892 | Siobhon Egan                                                                                                                                                                    |
| 890 |    599.665644 |    550.701709 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                   |
| 891 |    199.540843 |      5.512556 | T. Michael Keesey                                                                                                                                                               |
| 892 |    536.618235 |    671.182300 | Gabriel Lio, vectorized by Zimices                                                                                                                                              |
| 893 |    989.926864 |    163.725458 | Zimices                                                                                                                                                                         |
| 894 |    748.184666 |    110.128104 | Caleb M. Brown                                                                                                                                                                  |
| 895 |    563.929439 |    599.788674 | Zimices                                                                                                                                                                         |
| 896 |    410.726055 |    245.996704 | Caleb M. Brown                                                                                                                                                                  |
| 897 |    213.046611 |    297.749597 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 898 |    464.710092 |    258.125591 | David Orr                                                                                                                                                                       |
| 899 |    604.261826 |    636.496150 | Gareth Monger                                                                                                                                                                   |
| 900 |    716.415176 |    791.269045 | Oscar Sanisidro                                                                                                                                                                 |
| 901 |    590.334840 |    519.993381 | Matt Crook                                                                                                                                                                      |
| 902 |    575.179400 |    509.848836 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                      |
| 903 |    475.790505 |    713.361034 | Markus A. Grohme                                                                                                                                                                |
| 904 |    343.358612 |    431.375151 | NA                                                                                                                                                                              |
| 905 |    105.471806 |    412.372569 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                               |
| 906 |     76.902836 |    653.346500 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 907 |    345.323537 |    455.379045 | Hans Hillewaert                                                                                                                                                                 |
| 908 |     73.602445 |    467.870298 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                                       |
| 909 |    612.924638 |    214.823396 | Dean Schnabel                                                                                                                                                                   |
| 910 |    441.249118 |    588.330768 | Rene Martin                                                                                                                                                                     |
| 911 |    355.155330 |    665.526967 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                               |
| 912 |     84.077550 |    576.608025 | Matt Crook                                                                                                                                                                      |
| 913 |    463.750177 |    601.029703 | Jaime Headden                                                                                                                                                                   |
| 914 |      5.809151 |    787.283736 | Gareth Monger                                                                                                                                                                   |
| 915 |    998.070981 |    487.417992 | Stuart Humphries                                                                                                                                                                |
| 916 |    638.639246 |    137.237351 | Jessica Anne Miller                                                                                                                                                             |
| 917 |    822.997426 |    596.321645 | Steven Traver                                                                                                                                                                   |
| 918 |    770.928337 |    659.574535 | Felix Vaux                                                                                                                                                                      |
| 919 |    217.884218 |    308.564412 | Andrew A. Farke                                                                                                                                                                 |
| 920 |    571.038951 |    470.983293 | Andrew A. Farke                                                                                                                                                                 |
| 921 |    189.902300 |    567.515520 | Steven Traver                                                                                                                                                                   |

    #> Your tweet has been posted!
