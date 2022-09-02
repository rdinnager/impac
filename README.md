
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

Matt Crook, Tasman Dixon, CNZdenek, Becky Barnes, Lukas Panzarin,
Richard J. Harris, Tracy A. Heath, Steven Traver, Qiang Ou, Ghedo and T.
Michael Keesey, Griensteidl and T. Michael Keesey, Mathew Wedel, Michael
Scroggie, Jose Carlos Arenas-Monroy, Gareth Monger, Smokeybjb,
Benjamint444, Felix Vaux, Mattia Menchetti, Lankester Edwin Ray
(vectorized by T. Michael Keesey), Scott Hartman, terngirl, Margot
Michaud, Zimices, Jagged Fang Designs, Markus A. Grohme, Andy Wilson,
Darren Naish (vectorize by T. Michael Keesey), Aviceda (vectorized by T.
Michael Keesey), NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Ghedo (vectorized by
T. Michael Keesey), C. Camilo Julián-Caballero, Katie S. Collins, T.
Michael Keesey, Anthony Caravaggi, ArtFavor & annaleeblysse, Manabu
Bessho-Uehara, Yan Wong, Gabriela Palomo-Munoz, Christine Axon, Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Matt
Martyniuk (modified by T. Michael Keesey), Nobu Tamura (vectorized by T.
Michael Keesey), Alexis Simon, Ingo Braasch, Bennet McComish, photo by
Avenue, Walter Vladimir, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Steven Haddock • Jellywatch.org, Rebecca Groom, Armin Reindl,
Tony Ayling (vectorized by T. Michael Keesey), Iain Reid, Chris huh,
Pete Buchholz, Birgit Lang, Dean Schnabel, Maija Karala, Beth Reinke,
Leann Biancani, photo by Kenneth Clifton, Mo Hassan, Jaime Headden,
Robert Gay, Andrew A. Farke, FunkMonk \[Michael B.H.\] (modified by T.
Michael Keesey), Ghedoghedo, Todd Marshall, vectorized by Zimices, DW
Bapst (Modified from photograph taken by Charles Mitchell), Juan Carlos
Jerí, Birgit Lang; based on a drawing by C.L. Koch, Ferran Sayol, Emily
Willoughby, Nobu Tamura, Amanda Katzer, Joanna Wolfe, Erika Schumacher,
Mali’o Kodis, image from the Smithsonian Institution, Lafage, Sarah
Werning, Lip Kee Yap (vectorized by T. Michael Keesey), Catherine
Yasuda, Jack Mayer Wood, Renata F. Martins, L. Shyamal, I. Sáček,
Sr. (vectorized by T. Michael Keesey), M. Garfield & K. Anderson
(modified by T. Michael Keesey), David Orr, kreidefossilien.de, Matthias
Buschmann (vectorized by T. Michael Keesey), Xavier Giroux-Bougard,
Robert Hering, Robert Gay, modifed from Olegivvit, Caleb M. Brown,
FunkMonk, S.Martini, Frank Förster, H. F. O. March (vectorized by T.
Michael Keesey), Andrew Farke and Joseph Sertich, Pranav Iyer (grey
ideas), Sherman F. Denton via rawpixel.com (illustration) and Timothy J.
Bartley (silhouette), Smokeybjb, vectorized by Zimices, Cesar Julian,
Haplochromis (vectorized by T. Michael Keesey), Kai R. Caspar, Noah
Schlottman, photo by Carlos Sánchez-Ortiz, Sean McCann, Original photo
by Andrew Murray, vectorized by Roberto Díaz Sibaja, Gopal Murali,
Michelle Site, Kanako Bessho-Uehara, Dann Pigdon, Ignacio Contreras,
Martin Kevil, Dantheman9758 (vectorized by T. Michael Keesey), Scott
Reid, Alexander Schmidt-Lebuhn, Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Kosta Mumcuoglu
(vectorized by T. Michael Keesey), Tauana J. Cunha, Melissa Broussard,
Alexandre Vong, Darren Naish (vectorized by T. Michael Keesey), Scott
Hartman (modified by T. Michael Keesey), JCGiron, Josep Marti Solans,
Kamil S. Jaron, Lukas Panzarin (vectorized by T. Michael Keesey), James
I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel,
and Jelle P. Wiersma (vectorized by T. Michael Keesey), Stuart
Humphries, Konsta Happonen, Chuanixn Yu, Roger Witter, vectorized by
Zimices, xgirouxb, Kevin Sánchez, Robert Bruce Horsfall, vectorized by
Zimices, Hans Hillewaert (vectorized by T. Michael Keesey), Harold N
Eyster, JJ Harrison (vectorized by T. Michael Keesey), James R. Spotila
and Ray Chatterji, Matthew E. Clapham, Wynston Cooper (photo) and
Albertonykus (silhouette), Robbie N. Cada (vectorized by T. Michael
Keesey), Ludwik Gąsiorowski, Ellen Edmonson (illustration) and Timothy
J. Bartley (silhouette), Adam Stuart Smith (vectorized by T. Michael
Keesey), SecretJellyMan - from Mason McNair, Sergio A. Muñoz-Gómez, Emma
Hughes, George Edward Lodge (vectorized by T. Michael Keesey), DW Bapst
(modified from Mitchell 1990), Matt Wilkins, Sharon Wegner-Larsen, Alex
Slavenko, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), Chris Jennings (Risiatto),
Jake Warner, Mathieu Basille, Doug Backlund (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Didier Descouens
(vectorized by T. Michael Keesey), Burton Robert, USFWS, Jiekun He, Noah
Schlottman, photo by Gustav Paulay for Moorea Biocode, Dinah Challen,
Henry Lydecker, Noah Schlottman, Matt Dempsey, Mathieu Pélissié, Mali’o
Kodis, image from the Biodiversity Heritage Library, Tyler McCraney,
Martin R. Smith, after Skovsted et al 2015, Curtis Clark and T. Michael
Keesey, Brockhaus and Efron, T. Michael Keesey (after Heinrich Harder),
Roberto Díaz Sibaja, Meyer-Wachsmuth I, Curini Galletti M, Jondelius U
(<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong, Sidney
Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel),
Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja, T.
Michael Keesey (vector) and Stuart Halliday (photograph), T. Michael
Keesey (after Kukalová), John Conway, Carlos Cano-Barbacil, Joshua
Fowler, Riccardo Percudani, Cagri Cevrim, Stanton F. Fink (vectorized by
T. Michael Keesey), Agnello Picorelli, Inessa Voet, Andrew R. Gehrke,
SauropodomorphMonarch, Kelly, Ville-Veikko Sinkkonen, Tyler Greenfield,
Christoph Schomburg, Jessica Anne Miller, Matt Martyniuk, Marcos
Pérez-Losada, Jens T. Høeg & Keith A. Crandall, T. Michael Keesey (from
a mount by Allis Markham), FunkMonk (Michael B. H.), DW Bapst, modified
from Figure 1 of Belanger (2011, PALAIOS)., Collin Gross, M Kolmann,
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J.
Bartley (silhouette), New York Zoological Society, Maxime Dahirel,
Manabu Sakamoto, Michele Tobias, Ghedoghedo (vectorized by T. Michael
Keesey), Tess Linden, Karla Martinez, Yan Wong from wikipedia drawing
(PD: Pearson Scott Foresman), Dmitry Bogdanov, Antonov (vectorized by T.
Michael Keesey), Falconaumanni and T. Michael Keesey, T. Michael Keesey
(after Masteraah), A. R. McCulloch (vectorized by T. Michael Keesey),
White Wolf, Joe Schneid (vectorized by T. Michael Keesey), Sherman Foote
Denton (illustration, 1897) and Timothy J. Bartley (silhouette),
Meliponicultor Itaymbere, Lindberg (vectorized by T. Michael Keesey),
Michael Day, Christian A. Masnaghetti, Jerry Oldenettel (vectorized by
T. Michael Keesey), Jean-Raphaël Guillaumin (photography) and T. Michael
Keesey (vectorization), Fernando Carezzano, T. Michael Keesey (photo by
Darren Swim), Matus Valach, Skye M, Tarique Sani (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Julien Louys,
Noah Schlottman, photo by Hans De Blauwe, Scott Hartman (vectorized by
T. Michael Keesey), Jessica Rick, Ramona J Heim, Enoch Joseph Wetsy
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, François Michonneau, Danny Cicchetti (vectorized by T. Michael
Keesey), Nobu Tamura, vectorized by Zimices, Evan Swigart (photography)
and T. Michael Keesey (vectorization), Julio Garza, Diana Pomeroy, Nina
Skinner, Zachary Quigley, Pollyanna von Knorring and T. Michael Keesey,
Jakovche, Chris A. Hamilton, Craig Dylke, Steven Blackwood, Keith
Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, (after Spotila 2004), Jaime Chirinos (vectorized by T.
Michael Keesey), Lani Mohan, Duane Raver (vectorized by T. Michael
Keesey), Gustav Mützel, Patrick Fisher (vectorized by T. Michael
Keesey), Crystal Maier, Alexandra van der Geer, T. Tischler, Lauren
Sumner-Rooney, Taro Maeda, Steven Coombs, Cristian Osorio & Paula
Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org),
Tyler Greenfield and Dean Schnabel, Bill Bouton (source photo) & T.
Michael Keesey (vectorization), C. Abraczinskas, Noah Schlottman, photo
by Adam G. Clause, Acrocynus (vectorized by T. Michael Keesey), Mathilde
Cordellier, Mali’o Kodis, photograph by Cordell Expeditions at Cal
Academy, Apokryltaros (vectorized by T. Michael Keesey), Neil Kelley,
Lukasiniho, Karkemish (vectorized by T. Michael Keesey), Mariana Ruiz
(vectorized by T. Michael Keesey), Sebastian Stabinger, Andrés Sánchez,
Eric Moody, Timothy Knepp (vectorized by T. Michael Keesey), Dmitry
Bogdanov and FunkMonk (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                             |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    547.600954 |    437.542616 | Matt Crook                                                                                                                                                         |
|   2 |    375.412370 |    303.809643 | NA                                                                                                                                                                 |
|   3 |    722.500088 |    686.431150 | Tasman Dixon                                                                                                                                                       |
|   4 |    171.237438 |    337.726509 | Matt Crook                                                                                                                                                         |
|   5 |    846.798156 |    413.746367 | CNZdenek                                                                                                                                                           |
|   6 |    227.121280 |     58.166312 | Becky Barnes                                                                                                                                                       |
|   7 |    837.799767 |    493.287639 | Lukas Panzarin                                                                                                                                                     |
|   8 |    872.596364 |    313.801040 | Richard J. Harris                                                                                                                                                  |
|   9 |    895.125599 |    146.114591 | Tracy A. Heath                                                                                                                                                     |
|  10 |     77.415734 |    155.853683 | Steven Traver                                                                                                                                                      |
|  11 |    585.947303 |    733.854584 | Qiang Ou                                                                                                                                                           |
|  12 |    128.076515 |    456.973421 | Matt Crook                                                                                                                                                         |
|  13 |    759.697748 |    112.899659 | Ghedo and T. Michael Keesey                                                                                                                                        |
|  14 |    242.600951 |    191.502793 | Griensteidl and T. Michael Keesey                                                                                                                                  |
|  15 |    675.783605 |    359.363129 | Mathew Wedel                                                                                                                                                       |
|  16 |    546.223784 |    595.701963 | Michael Scroggie                                                                                                                                                   |
|  17 |    841.990521 |     55.001933 | Jose Carlos Arenas-Monroy                                                                                                                                          |
|  18 |    278.474520 |    711.922222 | Gareth Monger                                                                                                                                                      |
|  19 |     75.599649 |    734.380742 | Steven Traver                                                                                                                                                      |
|  20 |    725.156968 |    568.406513 | Tasman Dixon                                                                                                                                                       |
|  21 |    954.664957 |    308.362552 | Smokeybjb                                                                                                                                                          |
|  22 |    876.576743 |    720.046293 | Benjamint444                                                                                                                                                       |
|  23 |    413.143238 |    206.757172 | Steven Traver                                                                                                                                                      |
|  24 |    158.389664 |    617.084894 | Felix Vaux                                                                                                                                                         |
|  25 |    605.778849 |     63.584890 | Mattia Menchetti                                                                                                                                                   |
|  26 |    636.737501 |    486.487388 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                              |
|  27 |    831.168170 |    246.994301 | Scott Hartman                                                                                                                                                      |
|  28 |    543.100513 |    202.540185 | terngirl                                                                                                                                                           |
|  29 |    321.023637 |    507.478881 | Margot Michaud                                                                                                                                                     |
|  30 |    450.910688 |    108.732939 | Mathew Wedel                                                                                                                                                       |
|  31 |    475.578965 |     44.453128 | Zimices                                                                                                                                                            |
|  32 |    857.597429 |    194.184571 | Jagged Fang Designs                                                                                                                                                |
|  33 |    396.865411 |    642.568250 | Markus A. Grohme                                                                                                                                                   |
|  34 |    438.466076 |    733.270434 | Zimices                                                                                                                                                            |
|  35 |    661.373402 |    229.390028 | Matt Crook                                                                                                                                                         |
|  36 |    943.345220 |    537.494833 | Jose Carlos Arenas-Monroy                                                                                                                                          |
|  37 |    778.061575 |    727.607474 | Andy Wilson                                                                                                                                                        |
|  38 |    116.765729 |    233.239277 | Steven Traver                                                                                                                                                      |
|  39 |     82.531872 |    531.743968 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                      |
|  40 |    477.860260 |    397.172700 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                          |
|  41 |    793.000620 |    625.346795 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                              |
|  42 |    636.887187 |    131.696028 | Andy Wilson                                                                                                                                                        |
|  43 |    531.149160 |    525.230449 | Tasman Dixon                                                                                                                                                       |
|  44 |    709.826644 |    397.466528 | Jagged Fang Designs                                                                                                                                                |
|  45 |    428.629680 |    683.965599 | Jagged Fang Designs                                                                                                                                                |
|  46 |    327.341304 |    414.395945 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                            |
|  47 |    956.302873 |    697.650515 | C. Camilo Julián-Caballero                                                                                                                                         |
|  48 |    342.555862 |    169.452358 | Katie S. Collins                                                                                                                                                   |
|  49 |     34.487243 |    311.101849 | T. Michael Keesey                                                                                                                                                  |
|  50 |    120.285796 |     42.588527 | Anthony Caravaggi                                                                                                                                                  |
|  51 |    515.668042 |    153.148134 | Gareth Monger                                                                                                                                                      |
|  52 |    953.053787 |    225.318463 | ArtFavor & annaleeblysse                                                                                                                                           |
|  53 |    764.478921 |    305.690723 | Manabu Bessho-Uehara                                                                                                                                               |
|  54 |    729.786763 |    174.131850 | Yan Wong                                                                                                                                                           |
|  55 |    560.944372 |    292.999428 | Gabriela Palomo-Munoz                                                                                                                                              |
|  56 |    514.131243 |    653.587285 | NA                                                                                                                                                                 |
|  57 |    349.265766 |    599.553898 | Christine Axon                                                                                                                                                     |
|  58 |    545.770651 |    378.279832 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                   |
|  59 |    332.818721 |    117.538299 | Zimices                                                                                                                                                            |
|  60 |    856.269844 |    355.172725 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                     |
|  61 |     81.048194 |    384.726433 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  62 |    988.698431 |    129.915056 | Alexis Simon                                                                                                                                                       |
|  63 |    603.917025 |    535.249420 | Ingo Braasch                                                                                                                                                       |
|  64 |    957.849998 |     42.310741 | Tasman Dixon                                                                                                                                                       |
|  65 |    648.967441 |    449.693977 | Scott Hartman                                                                                                                                                      |
|  66 |    879.439380 |    599.750444 | Bennet McComish, photo by Avenue                                                                                                                                   |
|  67 |    439.840327 |    774.247414 | Felix Vaux                                                                                                                                                         |
|  68 |    412.271767 |    256.934597 | Jagged Fang Designs                                                                                                                                                |
|  69 |    959.977528 |    423.512911 | Andy Wilson                                                                                                                                                        |
|  70 |    326.695486 |    379.408934 | Walter Vladimir                                                                                                                                                    |
|  71 |    348.751133 |     70.720793 | Scott Hartman                                                                                                                                                      |
|  72 |    233.763219 |    441.199489 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  73 |    252.447171 |    329.435294 | T. Michael Keesey                                                                                                                                                  |
|  74 |     52.321516 |    627.100577 | Steven Haddock • Jellywatch.org                                                                                                                                    |
|  75 |    740.652854 |     21.375330 | Rebecca Groom                                                                                                                                                      |
|  76 |    264.840066 |    640.197138 | Scott Hartman                                                                                                                                                      |
|  77 |    311.506113 |     15.671083 | Armin Reindl                                                                                                                                                       |
|  78 |    713.585724 |    515.228204 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                      |
|  79 |    356.892186 |    759.216287 | Iain Reid                                                                                                                                                          |
|  80 |    198.968522 |    752.569238 | Chris huh                                                                                                                                                          |
|  81 |    314.445141 |    238.752108 | Pete Buchholz                                                                                                                                                      |
|  82 |    710.540332 |    428.361459 | Tasman Dixon                                                                                                                                                       |
|  83 |     43.323565 |     79.559262 | Birgit Lang                                                                                                                                                        |
|  84 |    473.872838 |    479.558411 | Dean Schnabel                                                                                                                                                      |
|  85 |    573.589071 |     91.054445 | T. Michael Keesey                                                                                                                                                  |
|  86 |    129.616725 |    155.752269 | terngirl                                                                                                                                                           |
|  87 |    264.635130 |     92.035648 | Maija Karala                                                                                                                                                       |
|  88 |    943.263800 |    774.623893 | Beth Reinke                                                                                                                                                        |
|  89 |    985.262682 |    344.145862 | Margot Michaud                                                                                                                                                     |
|  90 |    940.767731 |    707.836999 | Leann Biancani, photo by Kenneth Clifton                                                                                                                           |
|  91 |    473.920345 |    164.275865 | Mo Hassan                                                                                                                                                          |
|  92 |    373.479180 |    444.431944 | Jaime Headden                                                                                                                                                      |
|  93 |    530.444767 |    169.933203 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                      |
|  94 |    620.430633 |    767.515048 | Robert Gay                                                                                                                                                         |
|  95 |    823.376362 |    657.453423 | Andrew A. Farke                                                                                                                                                    |
|  96 |    451.534120 |    669.643071 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                          |
|  97 |     15.946888 |    251.382740 | Tracy A. Heath                                                                                                                                                     |
|  98 |    985.219614 |    458.375209 | Matt Crook                                                                                                                                                         |
|  99 |    885.470380 |    456.502948 | Ghedoghedo                                                                                                                                                         |
| 100 |    625.011467 |    589.872025 | Andy Wilson                                                                                                                                                        |
| 101 |    711.087332 |    733.518600 | Maija Karala                                                                                                                                                       |
| 102 |    491.959376 |    708.903327 | T. Michael Keesey                                                                                                                                                  |
| 103 |    666.642803 |    726.369700 | CNZdenek                                                                                                                                                           |
| 104 |     88.468210 |    490.685393 | Matt Crook                                                                                                                                                         |
| 105 |    655.502380 |    627.716632 | Todd Marshall, vectorized by Zimices                                                                                                                               |
| 106 |    522.262621 |    101.311282 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                      |
| 107 |     18.988605 |    775.273796 | Juan Carlos Jerí                                                                                                                                                   |
| 108 |    435.815066 |    354.308190 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 109 |    774.004757 |    211.125269 | Margot Michaud                                                                                                                                                     |
| 110 |    817.258926 |    596.595471 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                       |
| 111 |     19.684135 |     40.698138 | Zimices                                                                                                                                                            |
| 112 |    550.464307 |    565.423210 | Gareth Monger                                                                                                                                                      |
| 113 |    850.774034 |    547.257514 | Ferran Sayol                                                                                                                                                       |
| 114 |    397.385017 |    418.458692 | T. Michael Keesey                                                                                                                                                  |
| 115 |    105.307558 |    217.338177 | Gareth Monger                                                                                                                                                      |
| 116 |   1003.509257 |    703.657493 | Steven Traver                                                                                                                                                      |
| 117 |    905.262958 |    766.046990 | Emily Willoughby                                                                                                                                                   |
| 118 |    783.730778 |    256.894174 | Nobu Tamura                                                                                                                                                        |
| 119 |    273.185690 |    790.790311 | Amanda Katzer                                                                                                                                                      |
| 120 |    209.001956 |    723.733879 | Ferran Sayol                                                                                                                                                       |
| 121 |    276.904372 |    209.956724 | Ferran Sayol                                                                                                                                                       |
| 122 |    688.648135 |     78.058822 | Margot Michaud                                                                                                                                                     |
| 123 |    188.337179 |    203.652590 | Joanna Wolfe                                                                                                                                                       |
| 124 |    318.864949 |    733.704590 | Gareth Monger                                                                                                                                                      |
| 125 |    455.772887 |    619.217385 | Erika Schumacher                                                                                                                                                   |
| 126 |    403.851569 |    181.078509 | Birgit Lang                                                                                                                                                        |
| 127 |    766.256075 |    657.887939 | Steven Traver                                                                                                                                                      |
| 128 |    512.293491 |    787.891743 | Gabriela Palomo-Munoz                                                                                                                                              |
| 129 |    652.083103 |     47.679097 | Zimices                                                                                                                                                            |
| 130 |     31.875513 |    422.801497 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 131 |    421.715032 |    163.383769 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                               |
| 132 |    963.476491 |    349.522993 | Markus A. Grohme                                                                                                                                                   |
| 133 |    916.694463 |    756.636886 | Lafage                                                                                                                                                             |
| 134 |    234.303118 |    680.944131 | Sarah Werning                                                                                                                                                      |
| 135 |    765.220952 |    154.339622 | C. Camilo Julián-Caballero                                                                                                                                         |
| 136 |    331.967496 |    792.570323 | Zimices                                                                                                                                                            |
| 137 |     23.814586 |    112.772772 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                      |
| 138 |    722.584358 |    748.060391 | Catherine Yasuda                                                                                                                                                   |
| 139 |    240.344748 |    585.198779 | Margot Michaud                                                                                                                                                     |
| 140 |    932.340867 |    648.754413 | Chris huh                                                                                                                                                          |
| 141 |    882.372492 |    359.736085 | Jack Mayer Wood                                                                                                                                                    |
| 142 |    460.372169 |    689.216224 | Markus A. Grohme                                                                                                                                                   |
| 143 |    595.250429 |    504.099346 | Margot Michaud                                                                                                                                                     |
| 144 |    481.872448 |    221.503041 | Margot Michaud                                                                                                                                                     |
| 145 |    865.739669 |    506.342657 | Renata F. Martins                                                                                                                                                  |
| 146 |     60.243867 |    338.351013 | Andy Wilson                                                                                                                                                        |
| 147 |    622.210223 |     96.016859 | L. Shyamal                                                                                                                                                         |
| 148 |    292.012600 |     67.782730 | NA                                                                                                                                                                 |
| 149 |    281.133813 |    271.912415 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                    |
| 150 |    359.115158 |     10.742603 | Tasman Dixon                                                                                                                                                       |
| 151 |    194.968462 |    178.366869 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                          |
| 152 |     26.710085 |    207.887827 | Gareth Monger                                                                                                                                                      |
| 153 |    699.185808 |     60.723883 | Steven Traver                                                                                                                                                      |
| 154 |    593.564149 |     19.262045 | Scott Hartman                                                                                                                                                      |
| 155 |    234.268646 |    364.363668 | Margot Michaud                                                                                                                                                     |
| 156 |    274.969254 |    573.453176 | Jagged Fang Designs                                                                                                                                                |
| 157 |    511.791442 |    335.850166 | Smokeybjb                                                                                                                                                          |
| 158 |    217.019967 |      7.879659 | Ingo Braasch                                                                                                                                                       |
| 159 |     62.194013 |     45.724211 | NA                                                                                                                                                                 |
| 160 |    497.086780 |    224.386771 | David Orr                                                                                                                                                          |
| 161 |    166.106136 |    344.273411 | kreidefossilien.de                                                                                                                                                 |
| 162 |    637.823263 |    690.633073 | Gareth Monger                                                                                                                                                      |
| 163 |    930.282144 |    457.231025 | Gareth Monger                                                                                                                                                      |
| 164 |    253.888283 |    613.303078 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                               |
| 165 |     17.860996 |    446.092577 | NA                                                                                                                                                                 |
| 166 |     79.581494 |    618.926043 | Xavier Giroux-Bougard                                                                                                                                              |
| 167 |     77.891069 |      7.495630 | Robert Hering                                                                                                                                                      |
| 168 |      9.358632 |    172.723133 | Robert Gay, modifed from Olegivvit                                                                                                                                 |
| 169 |   1012.400752 |    496.552921 | Ferran Sayol                                                                                                                                                       |
| 170 |    717.276019 |    544.778681 | NA                                                                                                                                                                 |
| 171 |    516.412606 |    188.463422 | Gabriela Palomo-Munoz                                                                                                                                              |
| 172 |     68.032798 |    269.103303 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 173 |    270.823514 |    779.122317 | Jaime Headden                                                                                                                                                      |
| 174 |    316.778347 |    568.414121 | Caleb M. Brown                                                                                                                                                     |
| 175 |    389.105485 |     32.605449 | FunkMonk                                                                                                                                                           |
| 176 |    492.836634 |    438.430963 | Rebecca Groom                                                                                                                                                      |
| 177 |    271.009617 |    127.726885 | S.Martini                                                                                                                                                          |
| 178 |    531.813532 |    746.581438 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 179 |     64.040439 |    321.432797 | Frank Förster                                                                                                                                                      |
| 180 |    388.237019 |    705.831767 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                   |
| 181 |    710.517407 |    181.311073 | Andrew Farke and Joseph Sertich                                                                                                                                    |
| 182 |    736.397806 |    491.344805 | Gareth Monger                                                                                                                                                      |
| 183 |    204.205023 |    486.527208 | Matt Crook                                                                                                                                                         |
| 184 |    785.671681 |    554.142218 | Pranav Iyer (grey ideas)                                                                                                                                           |
| 185 |    169.629991 |    128.021533 | Scott Hartman                                                                                                                                                      |
| 186 |     76.419517 |    595.677930 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                              |
| 187 |     14.357993 |    508.381141 | Matt Crook                                                                                                                                                         |
| 188 |    665.636680 |    642.662348 | Smokeybjb, vectorized by Zimices                                                                                                                                   |
| 189 |    335.777767 |    353.591436 | S.Martini                                                                                                                                                          |
| 190 |    184.231481 |    164.477185 | Anthony Caravaggi                                                                                                                                                  |
| 191 |    367.158356 |    701.224812 | Gareth Monger                                                                                                                                                      |
| 192 |    597.247359 |    319.159498 | Scott Hartman                                                                                                                                                      |
| 193 |    574.116044 |    498.320936 | Cesar Julian                                                                                                                                                       |
| 194 |     86.921681 |    652.736411 | Scott Hartman                                                                                                                                                      |
| 195 |   1004.562330 |    750.097701 | Gareth Monger                                                                                                                                                      |
| 196 |    210.614978 |    698.392087 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                     |
| 197 |    488.704487 |    147.188297 | NA                                                                                                                                                                 |
| 198 |     39.961023 |     39.366481 | Gareth Monger                                                                                                                                                      |
| 199 |    755.551915 |    358.214522 | Gabriela Palomo-Munoz                                                                                                                                              |
| 200 |    449.593736 |    572.007103 | FunkMonk                                                                                                                                                           |
| 201 |    203.292331 |    141.351350 | Matt Crook                                                                                                                                                         |
| 202 |    201.094902 |    421.034313 | Kai R. Caspar                                                                                                                                                      |
| 203 |    701.223231 |    170.388014 | Sarah Werning                                                                                                                                                      |
| 204 |    635.420667 |    301.560521 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                     |
| 205 |    727.942290 |    240.721862 | Sean McCann                                                                                                                                                        |
| 206 |    389.942340 |    384.072601 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                 |
| 207 |    645.866216 |    605.429503 | Gopal Murali                                                                                                                                                       |
| 208 |    506.273928 |    262.516466 | Matt Crook                                                                                                                                                         |
| 209 |    276.070183 |    596.112941 | Michelle Site                                                                                                                                                      |
| 210 |    738.759067 |    271.072558 | Kanako Bessho-Uehara                                                                                                                                               |
| 211 |    474.107266 |    288.807186 | Dann Pigdon                                                                                                                                                        |
| 212 |    935.790004 |      7.913802 | Markus A. Grohme                                                                                                                                                   |
| 213 |    621.107035 |    671.998752 | Ignacio Contreras                                                                                                                                                  |
| 214 |    699.063121 |    535.508482 | NA                                                                                                                                                                 |
| 215 |    765.679609 |     81.829298 | Iain Reid                                                                                                                                                          |
| 216 |    280.538006 |    610.532803 | Margot Michaud                                                                                                                                                     |
| 217 |    651.861623 |    326.109899 | Martin Kevil                                                                                                                                                       |
| 218 |    664.948133 |    308.291215 | Scott Hartman                                                                                                                                                      |
| 219 |    690.969422 |    777.277105 | Gabriela Palomo-Munoz                                                                                                                                              |
| 220 |    837.377738 |    439.162072 | Matt Crook                                                                                                                                                         |
| 221 |    237.881636 |    771.415657 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                    |
| 222 |    584.510027 |    564.457955 | Gabriela Palomo-Munoz                                                                                                                                              |
| 223 |     49.388736 |    219.384325 | Beth Reinke                                                                                                                                                        |
| 224 |    441.015642 |     11.546463 | Margot Michaud                                                                                                                                                     |
| 225 |    729.729766 |     74.669164 | Scott Reid                                                                                                                                                         |
| 226 |    772.380601 |    582.518584 | Rebecca Groom                                                                                                                                                      |
| 227 |    540.097113 |     61.624677 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 228 |    997.247399 |    366.046255 | Andy Wilson                                                                                                                                                        |
| 229 |    537.000573 |    144.827050 | Emily Willoughby                                                                                                                                                   |
| 230 |    944.602269 |    503.507147 | NA                                                                                                                                                                 |
| 231 |    826.280497 |    132.497746 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 232 |     37.142064 |    535.262303 | Tasman Dixon                                                                                                                                                       |
| 233 |    560.216925 |    245.585490 | Matt Crook                                                                                                                                                         |
| 234 |   1005.378564 |    246.987861 | NA                                                                                                                                                                 |
| 235 |    417.071090 |    482.768900 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                  |
| 236 |    162.204917 |    268.362258 | Matt Crook                                                                                                                                                         |
| 237 |    476.257285 |    639.585132 | Zimices                                                                                                                                                            |
| 238 |    793.568567 |     92.242042 | Zimices                                                                                                                                                            |
| 239 |    906.180819 |    101.964824 | Steven Traver                                                                                                                                                      |
| 240 |    729.876856 |    605.442607 | Armin Reindl                                                                                                                                                       |
| 241 |    225.918356 |    463.703260 | T. Michael Keesey                                                                                                                                                  |
| 242 |    226.812997 |    112.210851 | Tauana J. Cunha                                                                                                                                                    |
| 243 |    211.416021 |    209.741640 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 244 |    761.253638 |    341.352799 | Zimices                                                                                                                                                            |
| 245 |     99.572612 |    610.431617 | Melissa Broussard                                                                                                                                                  |
| 246 |    712.215228 |    656.796751 | Chris huh                                                                                                                                                          |
| 247 |    796.492849 |    198.106480 | Zimices                                                                                                                                                            |
| 248 |    443.077671 |     91.224900 | Alexandre Vong                                                                                                                                                     |
| 249 |    633.264041 |    703.484663 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 250 |    952.594649 |    594.417647 | Margot Michaud                                                                                                                                                     |
| 251 |    540.942745 |    791.957792 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 252 |    688.810675 |    564.117181 | Zimices                                                                                                                                                            |
| 253 |    796.450831 |    133.629802 | Margot Michaud                                                                                                                                                     |
| 254 |    923.401880 |    416.947895 | T. Michael Keesey                                                                                                                                                  |
| 255 |    771.419553 |    281.074348 | Zimices                                                                                                                                                            |
| 256 |    475.693881 |    716.989816 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 257 |    303.875187 |    644.273355 | Zimices                                                                                                                                                            |
| 258 |   1016.853852 |    518.402623 | L. Shyamal                                                                                                                                                         |
| 259 |    299.667696 |    348.669797 | Jagged Fang Designs                                                                                                                                                |
| 260 |    567.455481 |    752.480631 | NA                                                                                                                                                                 |
| 261 |    654.203642 |    567.806050 | Scott Hartman                                                                                                                                                      |
| 262 |   1003.977973 |     57.933970 | Sarah Werning                                                                                                                                                      |
| 263 |    599.440217 |    625.475232 | NA                                                                                                                                                                 |
| 264 |    214.117730 |    579.795684 | Juan Carlos Jerí                                                                                                                                                   |
| 265 |    379.906616 |    358.193653 | NA                                                                                                                                                                 |
| 266 |    154.367066 |    225.193918 | Gareth Monger                                                                                                                                                      |
| 267 |     13.876081 |    519.693696 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                      |
| 268 |   1015.492733 |    565.831748 | JCGiron                                                                                                                                                            |
| 269 |    239.719276 |    246.676816 | Ferran Sayol                                                                                                                                                       |
| 270 |    109.612636 |     88.022662 | Scott Reid                                                                                                                                                         |
| 271 |    344.435749 |     33.865682 | Josep Marti Solans                                                                                                                                                 |
| 272 |    606.314803 |    331.179940 | Jaime Headden                                                                                                                                                      |
| 273 |    699.450087 |    130.003115 | Rebecca Groom                                                                                                                                                      |
| 274 |   1003.037455 |    658.850516 | Matt Crook                                                                                                                                                         |
| 275 |     19.397293 |    592.119467 | Dean Schnabel                                                                                                                                                      |
| 276 |    556.279963 |    465.692860 | Kamil S. Jaron                                                                                                                                                     |
| 277 |    856.346152 |    453.229448 | NA                                                                                                                                                                 |
| 278 |    973.359331 |    622.224620 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                   |
| 279 |    188.129707 |    529.067429 | JCGiron                                                                                                                                                            |
| 280 |     46.249027 |    113.115124 | Zimices                                                                                                                                                            |
| 281 |    308.205425 |    208.021600 | Zimices                                                                                                                                                            |
| 282 |    940.765332 |    732.772811 | Chris huh                                                                                                                                                          |
| 283 |    624.486665 |    401.682587 | Matt Crook                                                                                                                                                         |
| 284 |    945.486706 |    794.944847 | NA                                                                                                                                                                 |
| 285 |    534.337859 |    417.708001 | Jagged Fang Designs                                                                                                                                                |
| 286 |    998.260652 |    222.726886 | Steven Traver                                                                                                                                                      |
| 287 |    520.452951 |    421.895294 | T. Michael Keesey                                                                                                                                                  |
| 288 |    349.087500 |     48.766834 | Chris huh                                                                                                                                                          |
| 289 |     74.548762 |    609.547597 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                               |
| 290 |    925.354510 |    773.764674 | Juan Carlos Jerí                                                                                                                                                   |
| 291 |    165.743521 |    774.182766 | Stuart Humphries                                                                                                                                                   |
| 292 |    509.179555 |    132.776443 | Zimices                                                                                                                                                            |
| 293 |    675.215147 |    754.977778 | Sarah Werning                                                                                                                                                      |
| 294 |    791.086559 |    433.564875 | Konsta Happonen                                                                                                                                                    |
| 295 |    497.675285 |    428.061015 | Zimices                                                                                                                                                            |
| 296 |    202.020454 |    786.231822 | Margot Michaud                                                                                                                                                     |
| 297 |    717.102345 |    129.235889 | Steven Traver                                                                                                                                                      |
| 298 |    817.238486 |    781.301299 | Scott Hartman                                                                                                                                                      |
| 299 |    355.951146 |    779.871582 | Chuanixn Yu                                                                                                                                                        |
| 300 |    414.882057 |    444.263993 | Anthony Caravaggi                                                                                                                                                  |
| 301 |    589.674633 |    585.615044 | Dean Schnabel                                                                                                                                                      |
| 302 |     28.001959 |    612.687661 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 303 |    535.989087 |    240.207963 | Andy Wilson                                                                                                                                                        |
| 304 |     30.284779 |     12.679020 | Chris huh                                                                                                                                                          |
| 305 |    937.926481 |     75.201337 | Roger Witter, vectorized by Zimices                                                                                                                                |
| 306 |    675.653138 |    375.524730 | Zimices                                                                                                                                                            |
| 307 |    795.129124 |    777.339368 | Andy Wilson                                                                                                                                                        |
| 308 |    426.985607 |    242.405441 | NA                                                                                                                                                                 |
| 309 |    403.009326 |    119.269699 | xgirouxb                                                                                                                                                           |
| 310 |    467.185110 |    432.387141 | Kevin Sánchez                                                                                                                                                      |
| 311 |    189.701736 |    262.661577 | Chris huh                                                                                                                                                          |
| 312 |    568.865756 |     67.867001 | Michelle Site                                                                                                                                                      |
| 313 |    287.982022 |    119.317235 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                       |
| 314 |    884.096266 |    272.833173 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                  |
| 315 |    542.803444 |     26.152669 | Harold N Eyster                                                                                                                                                    |
| 316 |    220.568623 |    428.334619 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                      |
| 317 |     33.074362 |    170.335320 | Markus A. Grohme                                                                                                                                                   |
| 318 |    670.131722 |    322.775567 | Ignacio Contreras                                                                                                                                                  |
| 319 |     85.131026 |    272.356348 | Zimices                                                                                                                                                            |
| 320 |    678.547687 |    709.399442 | James R. Spotila and Ray Chatterji                                                                                                                                 |
| 321 |    352.906080 |     94.128277 | Scott Hartman                                                                                                                                                      |
| 322 |     66.130966 |    357.574790 | Matthew E. Clapham                                                                                                                                                 |
| 323 |    195.736755 |    238.886665 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                               |
| 324 |    309.476101 |    754.422873 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
| 325 |    807.386589 |    583.912568 | Katie S. Collins                                                                                                                                                   |
| 326 |    234.493697 |    267.685078 | Ludwik Gąsiorowski                                                                                                                                                 |
| 327 |    126.750727 |     16.843396 | Sarah Werning                                                                                                                                                      |
| 328 |    769.158862 |     92.205513 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                  |
| 329 |    562.027575 |     14.726447 | Beth Reinke                                                                                                                                                        |
| 330 |    811.632759 |    285.144722 | Gareth Monger                                                                                                                                                      |
| 331 |    791.892536 |    273.252508 | Birgit Lang                                                                                                                                                        |
| 332 |   1013.508352 |    412.448355 | Steven Traver                                                                                                                                                      |
| 333 |    378.122358 |    714.401347 | Tasman Dixon                                                                                                                                                       |
| 334 |    232.327549 |    417.272728 | NA                                                                                                                                                                 |
| 335 |    442.154739 |    541.698960 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                |
| 336 |    382.873625 |     82.343020 | Ferran Sayol                                                                                                                                                       |
| 337 |    593.686090 |    346.668886 | Emily Willoughby                                                                                                                                                   |
| 338 |    868.103713 |    704.174666 | Matt Crook                                                                                                                                                         |
| 339 |    921.216855 |    189.199761 | Birgit Lang                                                                                                                                                        |
| 340 |    819.488547 |    274.552949 | SecretJellyMan - from Mason McNair                                                                                                                                 |
| 341 |    844.326897 |    270.630780 | Gabriela Palomo-Munoz                                                                                                                                              |
| 342 |    532.224455 |    566.621379 | Steven Traver                                                                                                                                                      |
| 343 |    515.490917 |     84.068320 | Chris huh                                                                                                                                                          |
| 344 |    142.666381 |    105.643681 | Margot Michaud                                                                                                                                                     |
| 345 |    694.967716 |     99.458185 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 346 |    601.422736 |    306.851579 | Scott Hartman                                                                                                                                                      |
| 347 |    311.379918 |    775.818893 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 348 |    367.680351 |     12.593279 | Emma Hughes                                                                                                                                                        |
| 349 |     76.976517 |     28.750196 | Markus A. Grohme                                                                                                                                                   |
| 350 |    852.819674 |    104.053231 | NA                                                                                                                                                                 |
| 351 |   1009.483364 |    275.054106 | Margot Michaud                                                                                                                                                     |
| 352 |    416.533783 |    369.113040 | Gabriela Palomo-Munoz                                                                                                                                              |
| 353 |     36.561826 |    240.218078 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                              |
| 354 |    992.099392 |    417.779899 | DW Bapst (modified from Mitchell 1990)                                                                                                                             |
| 355 |    987.028818 |    288.752133 | James R. Spotila and Ray Chatterji                                                                                                                                 |
| 356 |    761.928529 |    188.991275 | Jagged Fang Designs                                                                                                                                                |
| 357 |     85.465949 |    342.131957 | Matt Wilkins                                                                                                                                                       |
| 358 |    400.003301 |    281.589477 | Ignacio Contreras                                                                                                                                                  |
| 359 |    227.605992 |    212.770002 | Matt Crook                                                                                                                                                         |
| 360 |    440.735920 |    497.594033 | Gabriela Palomo-Munoz                                                                                                                                              |
| 361 |    650.372496 |    756.192032 | Sharon Wegner-Larsen                                                                                                                                               |
| 362 |    481.693243 |    242.317014 | Alex Slavenko                                                                                                                                                      |
| 363 |     95.237350 |    642.745504 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 364 |    790.967350 |    578.308189 | Qiang Ou                                                                                                                                                           |
| 365 |    553.345427 |    673.206000 | Steven Traver                                                                                                                                                      |
| 366 |    632.926652 |     16.611023 | Felix Vaux                                                                                                                                                         |
| 367 |    465.220756 |    415.023988 | Joanna Wolfe                                                                                                                                                       |
| 368 |    588.774595 |     93.561174 | Chris Jennings (Risiatto)                                                                                                                                          |
| 369 |    806.209811 |    156.934728 | Steven Traver                                                                                                                                                      |
| 370 |    137.127736 |    789.907052 | Andy Wilson                                                                                                                                                        |
| 371 |    698.115207 |     12.590881 | Yan Wong                                                                                                                                                           |
| 372 |    420.126987 |    605.481511 | Gabriela Palomo-Munoz                                                                                                                                              |
| 373 |    750.499071 |    123.955838 | Zimices                                                                                                                                                            |
| 374 |     42.448088 |    785.546516 | Jake Warner                                                                                                                                                        |
| 375 |    500.976927 |    772.118619 | Dean Schnabel                                                                                                                                                      |
| 376 |    204.149907 |    520.677459 | Mathieu Basille                                                                                                                                                    |
| 377 |     13.377436 |    627.348450 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
| 378 |    251.529956 |    256.947630 | Chris huh                                                                                                                                                          |
| 379 |    667.735783 |    655.993277 | Scott Hartman                                                                                                                                                      |
| 380 |    914.061577 |    473.127909 | C. Camilo Julián-Caballero                                                                                                                                         |
| 381 |    809.300596 |     16.835110 | Matt Crook                                                                                                                                                         |
| 382 |   1009.169563 |    352.547072 | Andrew A. Farke                                                                                                                                                    |
| 383 |    721.749021 |    273.885424 | NA                                                                                                                                                                 |
| 384 |    549.573037 |    481.894138 | Pete Buchholz                                                                                                                                                      |
| 385 |    513.628020 |    695.319722 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 386 |    483.277714 |    303.185264 | Burton Robert, USFWS                                                                                                                                               |
| 387 |    974.731819 |    319.894278 | Margot Michaud                                                                                                                                                     |
| 388 |    459.047851 |    629.579207 | Margot Michaud                                                                                                                                                     |
| 389 |    483.319358 |    694.960727 | Jiekun He                                                                                                                                                          |
| 390 |    974.613945 |    452.861083 | Margot Michaud                                                                                                                                                     |
| 391 |    870.215893 |    792.029376 | Birgit Lang                                                                                                                                                        |
| 392 |     62.684265 |    790.842830 | Chris huh                                                                                                                                                          |
| 393 |    146.452936 |      7.166874 | Chuanixn Yu                                                                                                                                                        |
| 394 |    416.437959 |    504.385440 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                         |
| 395 |    861.284432 |    497.667226 | Jaime Headden                                                                                                                                                      |
| 396 |    844.416750 |    319.505940 | Dinah Challen                                                                                                                                                      |
| 397 |    672.360075 |    122.156866 | C. Camilo Julián-Caballero                                                                                                                                         |
| 398 |    449.315075 |    148.821691 | Henry Lydecker                                                                                                                                                     |
| 399 |    943.782231 |    260.593017 | Gabriela Palomo-Munoz                                                                                                                                              |
| 400 |     52.027692 |    763.651151 | Ferran Sayol                                                                                                                                                       |
| 401 |    985.457486 |     58.053923 | NA                                                                                                                                                                 |
| 402 |    569.122034 |    328.597949 | Noah Schlottman                                                                                                                                                    |
| 403 |    694.847207 |    361.691502 | Armin Reindl                                                                                                                                                       |
| 404 |     73.455682 |    205.785934 | Zimices                                                                                                                                                            |
| 405 |    428.771673 |    223.541306 | Gabriela Palomo-Munoz                                                                                                                                              |
| 406 |     77.356878 |    681.875768 | Matt Dempsey                                                                                                                                                       |
| 407 |    746.257167 |    783.356582 | Zimices                                                                                                                                                            |
| 408 |    220.584032 |    397.333266 | Mathieu Pélissié                                                                                                                                                   |
| 409 |    546.293647 |    456.474514 | Zimices                                                                                                                                                            |
| 410 |    496.879545 |     97.390980 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                         |
| 411 |    603.528409 |     39.150147 | Rebecca Groom                                                                                                                                                      |
| 412 |    845.874963 |    783.087021 | Zimices                                                                                                                                                            |
| 413 |     19.162418 |    564.884681 | Scott Reid                                                                                                                                                         |
| 414 |    385.224296 |    133.680590 | Margot Michaud                                                                                                                                                     |
| 415 |     28.949970 |    223.997753 | Margot Michaud                                                                                                                                                     |
| 416 |    256.127651 |     23.669734 | Birgit Lang                                                                                                                                                        |
| 417 |    694.475585 |    298.198373 | Dean Schnabel                                                                                                                                                      |
| 418 |    679.288106 |    309.863232 | Tyler McCraney                                                                                                                                                     |
| 419 |    359.562812 |    792.189840 | Emily Willoughby                                                                                                                                                   |
| 420 |    772.568812 |    687.123246 | Gabriela Palomo-Munoz                                                                                                                                              |
| 421 |     37.509770 |    524.224563 | Martin R. Smith, after Skovsted et al 2015                                                                                                                         |
| 422 |    303.611037 |    444.647366 | NA                                                                                                                                                                 |
| 423 |    345.342892 |    362.970537 | Ingo Braasch                                                                                                                                                       |
| 424 |    598.775498 |    272.485625 | Curtis Clark and T. Michael Keesey                                                                                                                                 |
| 425 |    448.082660 |    595.444973 | Scott Hartman                                                                                                                                                      |
| 426 |    691.876605 |    121.899583 | Scott Reid                                                                                                                                                         |
| 427 |    510.232469 |    750.123724 | S.Martini                                                                                                                                                          |
| 428 |    744.199249 |    187.795617 | Brockhaus and Efron                                                                                                                                                |
| 429 |    455.660497 |     61.369088 | Ferran Sayol                                                                                                                                                       |
| 430 |    551.405232 |    149.285627 | Gabriela Palomo-Munoz                                                                                                                                              |
| 431 |    998.541852 |    491.411598 | Matt Crook                                                                                                                                                         |
| 432 |    988.498077 |      8.592828 | Scott Hartman                                                                                                                                                      |
| 433 |    719.983366 |    405.218863 | Markus A. Grohme                                                                                                                                                   |
| 434 |    790.153477 |    664.478871 | Scott Hartman                                                                                                                                                      |
| 435 |    779.553203 |    350.198430 | Matt Crook                                                                                                                                                         |
| 436 |     88.706240 |     86.130801 | Zimices                                                                                                                                                            |
| 437 |   1015.915744 |     10.099729 | Andy Wilson                                                                                                                                                        |
| 438 |    406.227251 |     62.413280 | T. Michael Keesey (after Heinrich Harder)                                                                                                                          |
| 439 |    560.287393 |    770.563235 | Matt Crook                                                                                                                                                         |
| 440 |    706.113365 |    476.033592 | Roberto Díaz Sibaja                                                                                                                                                |
| 441 |    923.980306 |    260.563177 | Tasman Dixon                                                                                                                                                       |
| 442 |    155.189729 |    730.306049 | Zimices                                                                                                                                                            |
| 443 |    385.358291 |     47.437951 | Andrew A. Farke                                                                                                                                                    |
| 444 |    502.950038 |      3.864400 | Gareth Monger                                                                                                                                                      |
| 445 |    767.158752 |    249.121448 | Margot Michaud                                                                                                                                                     |
| 446 |     10.207264 |    687.909844 | Matt Crook                                                                                                                                                         |
| 447 |    847.459710 |    660.516155 | Jaime Headden                                                                                                                                                      |
| 448 |    770.335227 |    163.505115 | Margot Michaud                                                                                                                                                     |
| 449 |    510.127558 |    106.621568 | Margot Michaud                                                                                                                                                     |
| 450 |    629.513184 |    375.223738 | Jagged Fang Designs                                                                                                                                                |
| 451 |    554.769737 |     28.013668 | Jagged Fang Designs                                                                                                                                                |
| 452 |    639.594638 |    647.566392 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 453 |    768.739460 |    134.915617 | Markus A. Grohme                                                                                                                                                   |
| 454 |    617.382543 |     35.818666 | Yan Wong                                                                                                                                                           |
| 455 |    464.771974 |     96.751025 | Zimices                                                                                                                                                            |
| 456 |    456.312156 |    343.159735 | Jack Mayer Wood                                                                                                                                                    |
| 457 |    972.910240 |     22.307640 | Lafage                                                                                                                                                             |
| 458 |      7.753034 |    378.551981 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                   |
| 459 |    529.932091 |    764.197807 | T. Michael Keesey                                                                                                                                                  |
| 460 |    317.697377 |    132.976682 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 461 |    837.711509 |    586.334120 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 462 |    719.308652 |     48.256127 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                      |
| 463 |    269.609918 |    114.482813 | Birgit Lang                                                                                                                                                        |
| 464 |    797.620054 |    539.465644 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                 |
| 465 |    353.005417 |    372.266069 | Zimices                                                                                                                                                            |
| 466 |   1012.847108 |    387.695165 | NA                                                                                                                                                                 |
| 467 |    400.432828 |    492.446476 | FunkMonk                                                                                                                                                           |
| 468 |    827.202517 |    446.837135 | Joanna Wolfe                                                                                                                                                       |
| 469 |    829.371380 |    331.388711 | Ferran Sayol                                                                                                                                                       |
| 470 |    212.922357 |    782.824778 | Mattia Menchetti                                                                                                                                                   |
| 471 |    769.077396 |    792.447932 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                        |
| 472 |     20.080087 |    459.159687 | Steven Traver                                                                                                                                                      |
| 473 |    551.750723 |    345.363150 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 474 |    776.376925 |    324.736524 | Dean Schnabel                                                                                                                                                      |
| 475 |    809.767316 |    569.374321 | Matt Crook                                                                                                                                                         |
| 476 |    949.161657 |    755.850632 | T. Michael Keesey (after Kukalová)                                                                                                                                 |
| 477 |   1010.880955 |    789.320119 | John Conway                                                                                                                                                        |
| 478 |    702.687875 |    140.639524 | Carlos Cano-Barbacil                                                                                                                                               |
| 479 |    896.064011 |    791.073879 | Matt Crook                                                                                                                                                         |
| 480 |    827.755359 |    518.218877 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                      |
| 481 |    615.932766 |    172.365236 | Sean McCann                                                                                                                                                        |
| 482 |    967.272012 |    265.984448 | Gabriela Palomo-Munoz                                                                                                                                              |
| 483 |    960.822644 |    633.983595 | L. Shyamal                                                                                                                                                         |
| 484 |    400.031234 |    616.360165 | Ludwik Gąsiorowski                                                                                                                                                 |
| 485 |    573.206450 |    352.138563 | Joshua Fowler                                                                                                                                                      |
| 486 |    930.879507 |    592.111797 | Birgit Lang                                                                                                                                                        |
| 487 |    546.201800 |    766.151229 | Jagged Fang Designs                                                                                                                                                |
| 488 |    912.269099 |    704.231106 | L. Shyamal                                                                                                                                                         |
| 489 |    407.174718 |    383.919106 | Riccardo Percudani                                                                                                                                                 |
| 490 |     97.959569 |    286.163421 | Michael Scroggie                                                                                                                                                   |
| 491 |    363.405236 |    354.631520 | Matt Crook                                                                                                                                                         |
| 492 |   1009.644610 |    483.786362 | Anthony Caravaggi                                                                                                                                                  |
| 493 |    866.357449 |    656.393169 | NA                                                                                                                                                                 |
| 494 |    454.920799 |    508.125790 | Chris huh                                                                                                                                                          |
| 495 |    466.431178 |    226.482913 | Erika Schumacher                                                                                                                                                   |
| 496 |    322.566101 |    627.692656 | Steven Traver                                                                                                                                                      |
| 497 |    617.908383 |    319.324183 | Cagri Cevrim                                                                                                                                                       |
| 498 |     11.220003 |    145.107653 | Chris huh                                                                                                                                                          |
| 499 |    247.029392 |    785.387889 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                  |
| 500 |     62.809158 |    298.886503 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 501 |    685.670066 |    746.213284 | Ferran Sayol                                                                                                                                                       |
| 502 |    438.193222 |    378.477783 | Zimices                                                                                                                                                            |
| 503 |    278.912865 |    455.505635 | Roberto Díaz Sibaja                                                                                                                                                |
| 504 |    293.373577 |    764.630815 | Matt Crook                                                                                                                                                         |
| 505 |    602.282897 |    104.534289 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 506 |    291.298700 |    137.187773 | Agnello Picorelli                                                                                                                                                  |
| 507 |    847.382398 |    393.716611 | Zimices                                                                                                                                                            |
| 508 |    795.102529 |    517.297131 | Gareth Monger                                                                                                                                                      |
| 509 |    504.072365 |    119.159662 | Matt Crook                                                                                                                                                         |
| 510 |    899.618063 |    406.266094 | Gareth Monger                                                                                                                                                      |
| 511 |    559.113107 |    126.765030 | Inessa Voet                                                                                                                                                        |
| 512 |    907.900865 |    737.676279 | Andrew R. Gehrke                                                                                                                                                   |
| 513 |    730.762850 |    525.532477 | T. Michael Keesey                                                                                                                                                  |
| 514 |    978.721682 |    606.868414 | SauropodomorphMonarch                                                                                                                                              |
| 515 |    558.620332 |    138.799494 | Matt Crook                                                                                                                                                         |
| 516 |    549.529796 |    410.625747 | Gabriela Palomo-Munoz                                                                                                                                              |
| 517 |    931.753740 |    500.693333 | Steven Traver                                                                                                                                                      |
| 518 |     27.064817 |    186.080238 | Matt Crook                                                                                                                                                         |
| 519 |    542.660766 |    259.570296 | Kelly                                                                                                                                                              |
| 520 |    155.423934 |     85.733870 | Ville-Veikko Sinkkonen                                                                                                                                             |
| 521 |    569.045827 |    315.693773 | Scott Hartman                                                                                                                                                      |
| 522 |    179.222372 |    146.489120 | Tyler Greenfield                                                                                                                                                   |
| 523 |    398.078295 |    362.357366 | Gabriela Palomo-Munoz                                                                                                                                              |
| 524 |    162.318314 |    323.445969 | Chris huh                                                                                                                                                          |
| 525 |   1012.352766 |    615.280894 | Christoph Schomburg                                                                                                                                                |
| 526 |    724.621814 |    651.122274 | Jessica Anne Miller                                                                                                                                                |
| 527 |    973.593850 |    385.254432 | Katie S. Collins                                                                                                                                                   |
| 528 |    623.859406 |    788.873617 | Matt Martyniuk                                                                                                                                                     |
| 529 |    957.022243 |    355.059031 | Zimices                                                                                                                                                            |
| 530 |     30.703292 |    389.692723 | Smokeybjb                                                                                                                                                          |
| 531 |    914.034313 |     67.606877 | Brockhaus and Efron                                                                                                                                                |
| 532 |   1015.612926 |    602.029922 | Yan Wong                                                                                                                                                           |
| 533 |    553.227710 |     57.807436 | Alexandre Vong                                                                                                                                                     |
| 534 |     24.514047 |    755.350096 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                              |
| 535 |    990.020230 |    770.627681 | NA                                                                                                                                                                 |
| 536 |    743.902645 |    478.128595 | Ferran Sayol                                                                                                                                                       |
| 537 |    152.735914 |    186.865472 | Markus A. Grohme                                                                                                                                                   |
| 538 |    849.072173 |    169.663439 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                  |
| 539 |    820.742257 |    208.559394 | FunkMonk (Michael B. H.)                                                                                                                                           |
| 540 |    665.562410 |    713.718341 | L. Shyamal                                                                                                                                                         |
| 541 |    735.094866 |    252.872008 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                      |
| 542 |   1002.434702 |    175.943921 | Collin Gross                                                                                                                                                       |
| 543 |    910.540924 |     46.455851 | Ferran Sayol                                                                                                                                                       |
| 544 |    290.030348 |    781.461480 | Carlos Cano-Barbacil                                                                                                                                               |
| 545 |    882.679189 |    108.178421 | Steven Traver                                                                                                                                                      |
| 546 |    391.053381 |    692.642221 | Steven Traver                                                                                                                                                      |
| 547 |    306.780839 |     47.340678 | M Kolmann                                                                                                                                                          |
| 548 |    453.481324 |    719.493631 | Alexandre Vong                                                                                                                                                     |
| 549 |    750.448754 |    722.528495 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                           |
| 550 |    406.717686 |    592.589029 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 551 |    598.196801 |    602.482393 | Margot Michaud                                                                                                                                                     |
| 552 |    416.365324 |    181.988192 | New York Zoological Society                                                                                                                                        |
| 553 |    517.251006 |    564.332025 | Steven Traver                                                                                                                                                      |
| 554 |    307.768616 |    547.731760 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 555 |    342.938438 |    707.707431 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
| 556 |    187.223154 |     95.320560 | Gareth Monger                                                                                                                                                      |
| 557 |    555.320690 |    499.924160 | NA                                                                                                                                                                 |
| 558 |    714.421206 |    330.797204 | Zimices                                                                                                                                                            |
| 559 |    224.742167 |    550.109143 | Maxime Dahirel                                                                                                                                                     |
| 560 |    484.476690 |    449.234537 | Lafage                                                                                                                                                             |
| 561 |    745.633156 |    330.287028 | Manabu Sakamoto                                                                                                                                                    |
| 562 |    791.886684 |    329.528739 | Michele Tobias                                                                                                                                                     |
| 563 |    401.478330 |     21.795681 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 564 |    577.762011 |     38.198539 | Tess Linden                                                                                                                                                        |
| 565 |     85.356220 |    417.385500 | Dean Schnabel                                                                                                                                                      |
| 566 |    976.131376 |    641.569848 | Alex Slavenko                                                                                                                                                      |
| 567 |    470.160191 |    608.305133 | Steven Traver                                                                                                                                                      |
| 568 |    935.147099 |    607.245079 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                |
| 569 |    178.283147 |    325.885875 | Karla Martinez                                                                                                                                                     |
| 570 |    694.797004 |    313.568567 | Margot Michaud                                                                                                                                                     |
| 571 |     27.142249 |    746.571273 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                       |
| 572 |    774.994794 |    531.749535 | Dmitry Bogdanov                                                                                                                                                    |
| 573 |    143.069431 |    343.431701 | Roberto Díaz Sibaja                                                                                                                                                |
| 574 |    631.581128 |    461.799368 | Qiang Ou                                                                                                                                                           |
| 575 |     95.401037 |    600.853302 | Antonov (vectorized by T. Michael Keesey)                                                                                                                          |
| 576 |    186.434759 |    141.994667 | Gabriela Palomo-Munoz                                                                                                                                              |
| 577 |    443.100978 |    475.944976 | Ignacio Contreras                                                                                                                                                  |
| 578 |    917.064659 |     80.392144 | Birgit Lang                                                                                                                                                        |
| 579 |    980.280241 |    565.528390 | Erika Schumacher                                                                                                                                                   |
| 580 |    747.479204 |     61.971021 | Michelle Site                                                                                                                                                      |
| 581 |    888.488601 |    395.726613 | Falconaumanni and T. Michael Keesey                                                                                                                                |
| 582 |    999.856682 |    452.644115 | Gareth Monger                                                                                                                                                      |
| 583 |    994.991032 |     28.409515 | Jagged Fang Designs                                                                                                                                                |
| 584 |     21.788174 |    689.272269 | Matt Crook                                                                                                                                                         |
| 585 |     14.743983 |     77.365533 | T. Michael Keesey (after Masteraah)                                                                                                                                |
| 586 |     68.954028 |    609.164124 | T. Michael Keesey                                                                                                                                                  |
| 587 |    384.831379 |    453.404657 | Mo Hassan                                                                                                                                                          |
| 588 |    949.197424 |    610.283756 | NA                                                                                                                                                                 |
| 589 |      7.906134 |    653.388900 | Margot Michaud                                                                                                                                                     |
| 590 |    119.890214 |    269.102865 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 591 |    738.688875 |    414.502768 | Tasman Dixon                                                                                                                                                       |
| 592 |     28.329334 |    166.260170 | Matt Dempsey                                                                                                                                                       |
| 593 |    929.756980 |    329.997615 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                  |
| 594 |     38.783241 |    454.931780 | White Wolf                                                                                                                                                         |
| 595 |    923.625499 |    100.372327 | Margot Michaud                                                                                                                                                     |
| 596 |    300.036235 |    139.936458 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                      |
| 597 |    775.618592 |     53.814642 | Ferran Sayol                                                                                                                                                       |
| 598 |    582.129923 |    309.617607 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 599 |    270.573099 |     79.578428 | Margot Michaud                                                                                                                                                     |
| 600 |    259.918948 |    264.013866 | Kamil S. Jaron                                                                                                                                                     |
| 601 |     71.480513 |    407.285537 | Jagged Fang Designs                                                                                                                                                |
| 602 |    255.711891 |    583.931107 | Zimices                                                                                                                                                            |
| 603 |     90.192548 |    505.553163 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                      |
| 604 |    206.418252 |    461.079029 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 605 |    767.283177 |    179.715639 | Jagged Fang Designs                                                                                                                                                |
| 606 |    287.838392 |     88.109610 | Meliponicultor Itaymbere                                                                                                                                           |
| 607 |    917.578926 |    348.032839 | NA                                                                                                                                                                 |
| 608 |    188.227951 |      8.291656 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                         |
| 609 |    391.725672 |    472.103590 | Michael Day                                                                                                                                                        |
| 610 |    588.384446 |    446.617358 | Margot Michaud                                                                                                                                                     |
| 611 |    495.321676 |    314.561861 | Christine Axon                                                                                                                                                     |
| 612 |    896.601710 |    313.889787 | FunkMonk                                                                                                                                                           |
| 613 |    487.034979 |    723.492391 | Christian A. Masnaghetti                                                                                                                                           |
| 614 |    605.336741 |    453.952832 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                 |
| 615 |    696.736745 |    457.794269 | NA                                                                                                                                                                 |
| 616 |    870.201617 |    378.242594 | Kamil S. Jaron                                                                                                                                                     |
| 617 |    678.468360 |     65.266606 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                        |
| 618 |    491.845078 |    795.819684 | Fernando Carezzano                                                                                                                                                 |
| 619 |    614.407430 |    628.777499 | Steven Traver                                                                                                                                                      |
| 620 |    673.267446 |    465.550529 | Zimices                                                                                                                                                            |
| 621 |     35.015492 |    495.308568 | Ferran Sayol                                                                                                                                                       |
| 622 |    452.736474 |    748.196659 | Chris huh                                                                                                                                                          |
| 623 |     56.459498 |    551.177061 | NA                                                                                                                                                                 |
| 624 |    907.414906 |    721.069589 | Erika Schumacher                                                                                                                                                   |
| 625 |    900.017169 |    650.141213 | Beth Reinke                                                                                                                                                        |
| 626 |    414.414568 |    432.603075 | Andy Wilson                                                                                                                                                        |
| 627 |    211.910468 |    188.249927 | T. Michael Keesey (photo by Darren Swim)                                                                                                                           |
| 628 |    352.375228 |    604.932167 | Jiekun He                                                                                                                                                          |
| 629 |    266.192133 |    600.290096 | Jagged Fang Designs                                                                                                                                                |
| 630 |    945.054600 |     21.132295 | Ferran Sayol                                                                                                                                                       |
| 631 |    324.658828 |     44.246259 | Matus Valach                                                                                                                                                       |
| 632 |    922.156963 |    794.397589 | Ferran Sayol                                                                                                                                                       |
| 633 |     57.161664 |    746.173718 | Margot Michaud                                                                                                                                                     |
| 634 |    884.877441 |    691.527078 | Jagged Fang Designs                                                                                                                                                |
| 635 |    653.226539 |     27.561099 | NA                                                                                                                                                                 |
| 636 |    537.716423 |     97.229509 | Skye M                                                                                                                                                             |
| 637 |    118.423026 |    136.928123 | ArtFavor & annaleeblysse                                                                                                                                           |
| 638 |    696.967339 |    771.410291 | NA                                                                                                                                                                 |
| 639 |    425.940260 |    128.455813 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 640 |    247.736142 |    399.756767 | Gareth Monger                                                                                                                                                      |
| 641 |    984.802389 |    789.033978 | Dmitry Bogdanov                                                                                                                                                    |
| 642 |    923.444431 |    381.613840 | Julien Louys                                                                                                                                                       |
| 643 |    867.776932 |    466.591249 | Steven Traver                                                                                                                                                      |
| 644 |    874.664615 |    224.818669 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 645 |    714.001246 |    611.288295 | Zimices                                                                                                                                                            |
| 646 |    717.303480 |    469.030948 | Matt Martyniuk                                                                                                                                                     |
| 647 |     41.995048 |     63.481835 | NA                                                                                                                                                                 |
| 648 |      3.305144 |     78.040868 | NA                                                                                                                                                                 |
| 649 |    638.441890 |    769.956717 | Scott Hartman                                                                                                                                                      |
| 650 |    200.394643 |    721.666979 | NA                                                                                                                                                                 |
| 651 |    693.813237 |    641.548518 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                           |
| 652 |    835.595436 |    770.304629 | Steven Traver                                                                                                                                                      |
| 653 |    497.316383 |    497.514874 | Gareth Monger                                                                                                                                                      |
| 654 |    708.266231 |    312.806474 | Margot Michaud                                                                                                                                                     |
| 655 |    115.998469 |    555.396365 | Emily Willoughby                                                                                                                                                   |
| 656 |    753.518833 |    228.976415 | Melissa Broussard                                                                                                                                                  |
| 657 |    671.679822 |    338.633472 | Tasman Dixon                                                                                                                                                       |
| 658 |    702.884410 |    334.321313 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                    |
| 659 |    407.183915 |    105.712762 | Lafage                                                                                                                                                             |
| 660 |    626.161398 |    618.120615 | Jagged Fang Designs                                                                                                                                                |
| 661 |    113.639759 |    199.687281 | Matt Crook                                                                                                                                                         |
| 662 |     35.101051 |    670.838416 | Dean Schnabel                                                                                                                                                      |
| 663 |    548.033485 |    749.159443 | Matt Crook                                                                                                                                                         |
| 664 |    771.177620 |    186.338911 | Ignacio Contreras                                                                                                                                                  |
| 665 |   1014.516825 |    680.392616 | Jagged Fang Designs                                                                                                                                                |
| 666 |    610.745706 |    354.465094 | Zimices                                                                                                                                                            |
| 667 |    551.182554 |     86.954513 | Felix Vaux                                                                                                                                                         |
| 668 |    779.228188 |    406.401629 | NA                                                                                                                                                                 |
| 669 |     73.164301 |    562.638675 | Tauana J. Cunha                                                                                                                                                    |
| 670 |     78.103757 |    300.261716 | Zimices                                                                                                                                                            |
| 671 |    244.345061 |    105.513515 | Roberto Díaz Sibaja                                                                                                                                                |
| 672 |    567.896475 |    594.925482 | Jessica Rick                                                                                                                                                       |
| 673 |    115.084077 |    681.534913 | Zimices                                                                                                                                                            |
| 674 |    843.225397 |    705.296277 | Zimices                                                                                                                                                            |
| 675 |    901.851908 |    215.089065 | Ramona J Heim                                                                                                                                                      |
| 676 |   1014.635875 |    655.479910 | Zimices                                                                                                                                                            |
| 677 |    943.362227 |    245.048030 | Matt Crook                                                                                                                                                         |
| 678 |    858.485995 |    780.549961 | Matt Crook                                                                                                                                                         |
| 679 |    740.026371 |    451.943988 | Ferran Sayol                                                                                                                                                       |
| 680 |     15.211040 |    699.218738 | Melissa Broussard                                                                                                                                                  |
| 681 |    875.387493 |    205.674895 | Sarah Werning                                                                                                                                                      |
| 682 |    663.234831 |    474.193777 | Jaime Headden                                                                                                                                                      |
| 683 |    677.993015 |      6.181457 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 684 |    234.166764 |    403.616288 | Kamil S. Jaron                                                                                                                                                     |
| 685 |    943.516141 |    199.588338 | François Michonneau                                                                                                                                                |
| 686 |    567.783831 |    403.631804 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                  |
| 687 |    202.317222 |    276.428952 | Ignacio Contreras                                                                                                                                                  |
| 688 |    682.050617 |    135.758971 | Matt Crook                                                                                                                                                         |
| 689 |    465.950481 |    321.561575 | Anthony Caravaggi                                                                                                                                                  |
| 690 |    562.722934 |    795.526516 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 691 |    998.498182 |    511.348282 | NA                                                                                                                                                                 |
| 692 |    781.717654 |    678.512067 | NA                                                                                                                                                                 |
| 693 |    411.095024 |      9.945322 | S.Martini                                                                                                                                                          |
| 694 |    279.593106 |    194.488229 | Scott Hartman                                                                                                                                                      |
| 695 |    218.394288 |    770.207521 | Gareth Monger                                                                                                                                                      |
| 696 |    659.517379 |    786.170739 | Chris huh                                                                                                                                                          |
| 697 |    650.883610 |    700.229156 | L. Shyamal                                                                                                                                                         |
| 698 |    505.511641 |    601.975426 | Carlos Cano-Barbacil                                                                                                                                               |
| 699 |    421.887534 |    380.769985 | Matt Crook                                                                                                                                                         |
| 700 |    566.935020 |    565.260716 | Andrew A. Farke                                                                                                                                                    |
| 701 |    115.878067 |      8.222189 | Jaime Headden                                                                                                                                                      |
| 702 |    341.980442 |    678.151443 | Markus A. Grohme                                                                                                                                                   |
| 703 |    103.107220 |    306.888355 | Matt Crook                                                                                                                                                         |
| 704 |    564.223856 |    585.885768 | Zimices                                                                                                                                                            |
| 705 |    301.198128 |     75.717607 | Beth Reinke                                                                                                                                                        |
| 706 |    157.426057 |    782.277937 | Gabriela Palomo-Munoz                                                                                                                                              |
| 707 |    747.009079 |    345.390363 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                   |
| 708 |    929.153525 |    360.024503 | Julio Garza                                                                                                                                                        |
| 709 |    411.303251 |     48.575278 | Yan Wong                                                                                                                                                           |
| 710 |    959.099764 |    334.358298 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 711 |    333.984970 |    216.528903 | CNZdenek                                                                                                                                                           |
| 712 |    855.423173 |    385.226117 | Ferran Sayol                                                                                                                                                       |
| 713 |    572.580909 |     28.418404 | Diana Pomeroy                                                                                                                                                      |
| 714 |    585.876470 |    613.086828 | Nina Skinner                                                                                                                                                       |
| 715 |    643.560623 |    675.890494 | Juan Carlos Jerí                                                                                                                                                   |
| 716 |    928.177205 |    394.237514 | Zachary Quigley                                                                                                                                                    |
| 717 |    410.966974 |    417.267937 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                       |
| 718 |    698.646755 |    282.890214 | Gabriela Palomo-Munoz                                                                                                                                              |
| 719 |    972.381169 |    779.463729 | Yan Wong                                                                                                                                                           |
| 720 |    370.588877 |     94.050028 | Jakovche                                                                                                                                                           |
| 721 |     92.681033 |    325.944307 | Chris A. Hamilton                                                                                                                                                  |
| 722 |    857.342173 |    252.742914 | Craig Dylke                                                                                                                                                        |
| 723 |    877.406031 |     99.191939 | Scott Hartman                                                                                                                                                      |
| 724 |      9.376485 |    104.938003 | Steven Blackwood                                                                                                                                                   |
| 725 |    652.914796 |    769.990245 | C. Camilo Julián-Caballero                                                                                                                                         |
| 726 |    780.117056 |    434.451485 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
| 727 |    681.144390 |    584.465910 | (after Spotila 2004)                                                                                                                                               |
| 728 |    736.567156 |     54.851644 | Gareth Monger                                                                                                                                                      |
| 729 |    461.193101 |    536.513755 | Matt Crook                                                                                                                                                         |
| 730 |    657.360149 |    690.825848 | Margot Michaud                                                                                                                                                     |
| 731 |    521.355452 |    259.841292 | Scott Hartman                                                                                                                                                      |
| 732 |    647.200223 |    501.996708 | Zimices                                                                                                                                                            |
| 733 |    279.062239 |    386.393847 | David Orr                                                                                                                                                          |
| 734 |    861.654757 |    164.855843 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                   |
| 735 |    193.771920 |    716.365766 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                   |
| 736 |    209.977903 |    102.939986 | Matt Crook                                                                                                                                                         |
| 737 |    413.136930 |    579.003323 | Margot Michaud                                                                                                                                                     |
| 738 |    939.140972 |    286.582680 | Matt Crook                                                                                                                                                         |
| 739 |    465.451210 |    446.934038 | Lani Mohan                                                                                                                                                         |
| 740 |    943.478937 |     88.212713 | Gabriela Palomo-Munoz                                                                                                                                              |
| 741 |    684.744798 |    151.115831 | Jiekun He                                                                                                                                                          |
| 742 |    742.997919 |     86.492753 | FunkMonk                                                                                                                                                           |
| 743 |     22.635549 |    123.630305 | C. Camilo Julián-Caballero                                                                                                                                         |
| 744 |    608.630740 |    584.501564 | Michelle Site                                                                                                                                                      |
| 745 |    447.156666 |    276.547027 | Chris huh                                                                                                                                                          |
| 746 |    521.703500 |     15.165637 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 747 |    429.182995 |    561.640698 | FunkMonk                                                                                                                                                           |
| 748 |    666.633896 |    159.021554 | Steven Traver                                                                                                                                                      |
| 749 |    119.616996 |    288.627743 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                      |
| 750 |    681.634867 |    359.800413 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 751 |    335.150684 |    392.848817 | xgirouxb                                                                                                                                                           |
| 752 |    983.795931 |    583.994552 | Ferran Sayol                                                                                                                                                       |
| 753 |    462.807942 |    598.931134 | Steven Traver                                                                                                                                                      |
| 754 |    156.757045 |    137.069541 | Gareth Monger                                                                                                                                                      |
| 755 |    137.676086 |    796.135418 | NA                                                                                                                                                                 |
| 756 |    910.600726 |    452.701736 | Gabriela Palomo-Munoz                                                                                                                                              |
| 757 |    967.113162 |    367.690714 | Sarah Werning                                                                                                                                                      |
| 758 |    927.976509 |    272.030122 | Chris huh                                                                                                                                                          |
| 759 |    627.295346 |    331.833471 | Jagged Fang Designs                                                                                                                                                |
| 760 |    228.526115 |    663.602517 | Scott Hartman                                                                                                                                                      |
| 761 |    760.013345 |    518.375729 | Christoph Schomburg                                                                                                                                                |
| 762 |     24.616886 |    624.892819 | Ignacio Contreras                                                                                                                                                  |
| 763 |    683.617236 |    337.842311 | Steven Traver                                                                                                                                                      |
| 764 |    905.375105 |    340.168756 | NA                                                                                                                                                                 |
| 765 |   1008.725228 |    673.733884 | Gustav Mützel                                                                                                                                                      |
| 766 |    610.790693 |    614.644000 | Ferran Sayol                                                                                                                                                       |
| 767 |     51.964239 |    237.315667 | Matt Crook                                                                                                                                                         |
| 768 |    151.114316 |    493.573622 | Anthony Caravaggi                                                                                                                                                  |
| 769 |    868.810528 |    349.993464 | Iain Reid                                                                                                                                                          |
| 770 |    518.722423 |    711.672700 | Gabriela Palomo-Munoz                                                                                                                                              |
| 771 |    930.057416 |    658.707367 | Gareth Monger                                                                                                                                                      |
| 772 |     79.688568 |    285.583933 | Yan Wong                                                                                                                                                           |
| 773 |    896.220671 |    474.828104 | Zimices                                                                                                                                                            |
| 774 |   1007.458719 |    295.429745 | Jaime Headden                                                                                                                                                      |
| 775 |    912.460178 |    639.702997 | Ferran Sayol                                                                                                                                                       |
| 776 |    453.527422 |    246.318558 | Andy Wilson                                                                                                                                                        |
| 777 |    130.949810 |    276.245964 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 778 |    166.030015 |    795.096861 | Michelle Site                                                                                                                                                      |
| 779 |    140.318010 |    202.965866 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                   |
| 780 |    103.404395 |    349.496002 | Yan Wong                                                                                                                                                           |
| 781 |    415.512992 |    139.656809 | Felix Vaux                                                                                                                                                         |
| 782 |    395.015745 |    440.069861 | Birgit Lang                                                                                                                                                        |
| 783 |    206.678300 |    167.332044 | Crystal Maier                                                                                                                                                      |
| 784 |    902.932482 |    226.157199 | Chris huh                                                                                                                                                          |
| 785 |    175.519860 |    254.378237 | Alexandra van der Geer                                                                                                                                             |
| 786 |     21.943804 |    229.400102 | T. Tischler                                                                                                                                                        |
| 787 |    693.669093 |    714.742470 | CNZdenek                                                                                                                                                           |
| 788 |    999.901560 |    576.721225 | Steven Traver                                                                                                                                                      |
| 789 |    598.891717 |    118.487419 | Ferran Sayol                                                                                                                                                       |
| 790 |    475.574803 |    326.775003 | Lauren Sumner-Rooney                                                                                                                                               |
| 791 |    892.346175 |     10.101838 | Yan Wong                                                                                                                                                           |
| 792 |    663.540220 |    605.680979 | Margot Michaud                                                                                                                                                     |
| 793 |    444.080656 |    319.015421 | Sharon Wegner-Larsen                                                                                                                                               |
| 794 |    963.696805 |    486.291345 | NA                                                                                                                                                                 |
| 795 |    346.610423 |    450.826256 | Zimices                                                                                                                                                            |
| 796 |    919.070777 |    434.246121 | Juan Carlos Jerí                                                                                                                                                   |
| 797 |    211.210631 |    535.675301 | Kamil S. Jaron                                                                                                                                                     |
| 798 |    887.745575 |    212.936756 | Kai R. Caspar                                                                                                                                                      |
| 799 |    700.506877 |    489.107657 | Gareth Monger                                                                                                                                                      |
| 800 |    101.042356 |    391.635993 | Ferran Sayol                                                                                                                                                       |
| 801 |     83.320117 |    660.277300 | Zimices                                                                                                                                                            |
| 802 |    131.725445 |    264.963553 | Jagged Fang Designs                                                                                                                                                |
| 803 |    662.133216 |    775.299928 | Jagged Fang Designs                                                                                                                                                |
| 804 |    891.517133 |    496.091566 | Jagged Fang Designs                                                                                                                                                |
| 805 |    464.598419 |    232.341741 | xgirouxb                                                                                                                                                           |
| 806 |   1015.950307 |    446.585953 | Matt Crook                                                                                                                                                         |
| 807 |    898.888150 |    273.963382 | Taro Maeda                                                                                                                                                         |
| 808 |    274.189223 |    358.449341 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
| 809 |    664.098463 |    440.193737 | Tasman Dixon                                                                                                                                                       |
| 810 |    891.052812 |    464.268157 | Steven Coombs                                                                                                                                                      |
| 811 |    384.322813 |    567.979696 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 812 |    948.465666 |    102.137695 | Alexis Simon                                                                                                                                                       |
| 813 |    906.431057 |     69.897410 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                       |
| 814 |    837.544905 |    154.033987 | Gabriela Palomo-Munoz                                                                                                                                              |
| 815 |    308.669736 |    781.919473 | Zimices                                                                                                                                                            |
| 816 |    215.475347 |     22.929327 | Gareth Monger                                                                                                                                                      |
| 817 |     20.515407 |    665.859045 | Anthony Caravaggi                                                                                                                                                  |
| 818 |    698.196138 |    758.588640 | Tyler Greenfield and Dean Schnabel                                                                                                                                 |
| 819 |    705.423993 |    774.956558 | NA                                                                                                                                                                 |
| 820 |    529.218308 |    157.168662 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                     |
| 821 |    337.115909 |    659.921152 | Birgit Lang                                                                                                                                                        |
| 822 |    187.322359 |     25.304607 | Steven Traver                                                                                                                                                      |
| 823 |    498.729110 |    630.297952 | C. Abraczinskas                                                                                                                                                    |
| 824 |     21.858188 |    579.306962 | Gabriela Palomo-Munoz                                                                                                                                              |
| 825 |    870.398213 |    265.765008 | Scott Reid                                                                                                                                                         |
| 826 |    975.649864 |    399.396697 | Zimices                                                                                                                                                            |
| 827 |    729.084954 |    775.834993 | Zimices                                                                                                                                                            |
| 828 |    836.387569 |    210.889793 | Margot Michaud                                                                                                                                                     |
| 829 |    191.057190 |    572.118208 | Gabriela Palomo-Munoz                                                                                                                                              |
| 830 |    816.973931 |    199.936738 | Steven Traver                                                                                                                                                      |
| 831 |    347.253848 |    617.986900 | Steven Traver                                                                                                                                                      |
| 832 |    450.590161 |    488.618865 | Gabriela Palomo-Munoz                                                                                                                                              |
| 833 |    697.767522 |    106.466160 | Tasman Dixon                                                                                                                                                       |
| 834 |    718.957586 |     61.533436 | Noah Schlottman, photo by Adam G. Clause                                                                                                                           |
| 835 |    969.343653 |    660.349081 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 836 |    399.604942 |    373.530634 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                        |
| 837 |    950.051908 |    292.964038 | Riccardo Percudani                                                                                                                                                 |
| 838 |    587.000530 |    332.277420 | NA                                                                                                                                                                 |
| 839 |    958.315792 |    328.219025 | Birgit Lang                                                                                                                                                        |
| 840 |    750.975858 |    170.474728 | Chuanixn Yu                                                                                                                                                        |
| 841 |   1012.859489 |    370.497777 | Mathilde Cordellier                                                                                                                                                |
| 842 |    200.917566 |    613.818430 | Andy Wilson                                                                                                                                                        |
| 843 |    370.992124 |     41.059298 | Gareth Monger                                                                                                                                                      |
| 844 |    742.148797 |    741.335969 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                     |
| 845 |    816.732898 |    385.498815 | Gareth Monger                                                                                                                                                      |
| 846 |    869.135786 |      8.947846 | Matt Crook                                                                                                                                                         |
| 847 |    410.996068 |    613.757775 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                     |
| 848 |     91.634322 |    791.959824 | Gabriela Palomo-Munoz                                                                                                                                              |
| 849 |    878.893189 |     16.824361 | NA                                                                                                                                                                 |
| 850 |    174.608791 |    108.315876 | Margot Michaud                                                                                                                                                     |
| 851 |    706.441553 |    157.515286 | Steven Traver                                                                                                                                                      |
| 852 |    760.374772 |    489.616589 | Gabriela Palomo-Munoz                                                                                                                                              |
| 853 |    522.269262 |    182.199491 | Matt Crook                                                                                                                                                         |
| 854 |    365.759365 |    283.322196 | Zimices                                                                                                                                                            |
| 855 |    714.973280 |    719.257028 | Matt Crook                                                                                                                                                         |
| 856 |    824.853941 |    431.768331 | M Kolmann                                                                                                                                                          |
| 857 |    107.605332 |    402.731842 | Zimices                                                                                                                                                            |
| 858 |    505.277969 |    715.363847 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                      |
| 859 |      8.376458 |    790.768849 | Ferran Sayol                                                                                                                                                       |
| 860 |    912.825984 |    492.303352 | Neil Kelley                                                                                                                                                        |
| 861 |    266.111280 |    398.293966 | Margot Michaud                                                                                                                                                     |
| 862 |    950.722449 |    184.557472 | Lukasiniho                                                                                                                                                         |
| 863 |    176.932885 |    769.887473 | Jaime Headden                                                                                                                                                      |
| 864 |    409.175821 |    227.581791 | Birgit Lang                                                                                                                                                        |
| 865 |    260.615746 |    125.358390 | Matt Crook                                                                                                                                                         |
| 866 |     67.685761 |    491.154963 | T. Michael Keesey                                                                                                                                                  |
| 867 |    362.961465 |    139.343245 | Gareth Monger                                                                                                                                                      |
| 868 |    949.178117 |    342.060994 | Matt Crook                                                                                                                                                         |
| 869 |    987.353853 |    247.203647 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 870 |    346.780922 |    689.246532 | Noah Schlottman, photo by Adam G. Clause                                                                                                                           |
| 871 |    589.195355 |    136.522236 | Iain Reid                                                                                                                                                          |
| 872 |    560.303114 |    783.306578 | Matt Crook                                                                                                                                                         |
| 873 |    418.568199 |    573.028676 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                        |
| 874 |    615.454045 |    282.326901 | Margot Michaud                                                                                                                                                     |
| 875 |     11.562374 |    359.934092 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                     |
| 876 |    902.194157 |    619.627631 | Zimices                                                                                                                                                            |
| 877 |    536.109783 |    686.168945 | Zimices                                                                                                                                                            |
| 878 |    645.664173 |    712.190712 | Sebastian Stabinger                                                                                                                                                |
| 879 |    345.259161 |    568.064156 | Gareth Monger                                                                                                                                                      |
| 880 |     10.890143 |    219.433129 | Markus A. Grohme                                                                                                                                                   |
| 881 |      5.937760 |    552.526407 | Andrés Sánchez                                                                                                                                                     |
| 882 |    486.381935 |    755.253436 | Eric Moody                                                                                                                                                         |
| 883 |    595.707501 |    129.597179 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                    |
| 884 |    313.480246 |     75.801808 | Steven Traver                                                                                                                                                      |
| 885 |    480.404839 |    270.625229 | Jaime Headden                                                                                                                                                      |
| 886 |    893.027521 |    204.468708 | Roberto Díaz Sibaja                                                                                                                                                |
| 887 |      9.778307 |    471.139740 | Matt Crook                                                                                                                                                         |
| 888 |    923.408484 |    475.015941 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 889 |    190.691412 |    774.998067 | Zimices                                                                                                                                                            |
| 890 |    296.505712 |    606.346446 | Joanna Wolfe                                                                                                                                                       |
| 891 |    717.342650 |    528.004611 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                     |
| 892 |    738.671057 |    545.182718 | Tauana J. Cunha                                                                                                                                                    |
| 893 |    333.066438 |    250.135510 | CNZdenek                                                                                                                                                           |
| 894 |     72.159327 |    552.151094 | Joanna Wolfe                                                                                                                                                       |
| 895 |    344.217371 |    672.380938 | Jagged Fang Designs                                                                                                                                                |
| 896 |    769.975538 |    449.588791 | Gareth Monger                                                                                                                                                      |
| 897 |    601.115932 |    172.780510 | L. Shyamal                                                                                                                                                         |
| 898 |    126.981941 |    196.670230 | Qiang Ou                                                                                                                                                           |
| 899 |    440.502525 |    614.213109 | Matt Crook                                                                                                                                                         |
| 900 |    540.254281 |    678.899679 | Collin Gross                                                                                                                                                       |
| 901 |    884.790865 |    197.151246 | Nina Skinner                                                                                                                                                       |
| 902 |    938.283392 |    582.126724 | Christoph Schomburg                                                                                                                                                |
| 903 |    592.364688 |    228.274144 | Jessica Rick                                                                                                                                                       |
| 904 |    225.344722 |    653.933308 | Matt Crook                                                                                                                                                         |
| 905 |    401.356670 |     95.919257 | T. Michael Keesey                                                                                                                                                  |
| 906 |    442.333436 |    334.268812 | Cesar Julian                                                                                                                                                       |

    #> Your tweet has been posted!
