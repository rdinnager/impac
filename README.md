
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

Dean Schnabel, Ferran Sayol, Scott Hartman, Steven Traver, Pranav Iyer
(grey ideas), Zimices, Jaime Headden, Margot Michaud, Matt Crook, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), T. Michael Keesey, Michele M Tobias from an image
By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Carlos
Cano-Barbacil, Jagged Fang Designs, Gabriela Palomo-Munoz, Sarah
Werning, Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., Nobu Tamura (vectorized by T. Michael Keesey), Jaime
Chirinos (vectorized by T. Michael Keesey), Katie S. Collins, Rene
Martin, T. Michael Keesey (vectorization) and Nadiatalent (photography),
Steven Coombs, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Danielle Alba, Christian A. Masnaghetti, Mali’o Kodis, image from the
“Proceedings of the Zoological Society of London”, Joanna Wolfe,
Rebecca Groom, Terpsichores, A. R. McCulloch (vectorized by T. Michael
Keesey), Benjamint444, Brad McFeeters (vectorized by T. Michael Keesey),
Todd Marshall, vectorized by Zimices, T. Michael Keesey (after Monika
Betley), Andrew A. Farke, Markus A. Grohme, Matt Wilkins, Ghedo
(vectorized by T. Michael Keesey), Birgit Lang, Juan Carlos Jerí, Nobu
Tamura, vectorized by Zimices, Tracy A. Heath, Stuart Humphries, Robert
Bruce Horsfall, vectorized by Zimices, Andy Wilson, Leon P. A. M.
Claessens, Patrick M. O’Connor, David M. Unwin, Smokeybjb, Alex
Slavenko, Caleb M. Brown, Mali’o Kodis, image from the Biodiversity
Heritage Library, Ian Burt (original) and T. Michael Keesey
(vectorization), Alexander Schmidt-Lebuhn, Mathilde Cordellier, Harold N
Eyster, Chuanixn Yu, Noah Schlottman, photo by Casey Dunn, Ignacio
Contreras, Cesar Julian, James I. Kirkland, Luis Alcalá, Mark A. Loewen,
Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T.
Michael Keesey), Hugo Gruson, Felix Vaux, Iain Reid, Amanda Katzer,
Jesús Gómez, vectorized by Zimices, Jack Mayer Wood, Fernando
Carezzano, Shyamal, Michelle Site, Gareth Monger, Christoph Schomburg,
Peileppe, Blanco et al., 2014, vectorized by Zimices, T. Michael Keesey
(after Mauricio Antón), Roberto Díaz Sibaja, Ingo Braasch, Pete
Buchholz, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Erika Schumacher, Michele
Tobias, Renato de Carvalho Ferreira, I. Sáček, Sr. (vectorized by T.
Michael Keesey), Tasman Dixon, Chris huh, Tauana J. Cunha, Emily
Willoughby, André Karwath (vectorized by T. Michael Keesey), Neil
Kelley, Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M.
Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Maija
Karala, Taro Maeda, L. Shyamal, Kai R. Caspar, Caroline Harding, MAF
(vectorized by T. Michael Keesey), Hans Hillewaert (vectorized by T.
Michael Keesey), Mathew Stewart, Becky Barnes, Mason McNair, ДиБгд
(vectorized by T. Michael Keesey), Jiekun He, Tyler Greenfield and Scott
Hartman, Steven Haddock • Jellywatch.org, Birgit Lang; based on a
drawing by C.L. Koch, Cristopher Silva, Matt Hayes, Bryan Carstens, T.
Michael Keesey (after A. Y. Ivantsov), Martien Brand (original photo),
Renato Santos (vector silhouette), Collin Gross, Darren Naish
(vectorized by T. Michael Keesey), Alexandre Vong, Oscar Sanisidro,
Michael P. Taylor, Kamil S. Jaron, V. Deepak, \[unknown\], Michele M
Tobias, Liftarn, Chase Brownstein, Jean-Raphaël Guillaumin (photography)
and T. Michael Keesey (vectorization), Martin R. Smith, after Skovsted
et al 2015, SecretJellyMan, Andrew A. Farke, shell lines added by Yan
Wong, Ludwik Gąsiorowski, Kent Elson Sorgon, Samanta Orellana, Marcos
Pérez-Losada, Jens T. Høeg & Keith A. Crandall, Arthur S. Brum, Matt
Martyniuk, Dinah Challen, Robert Gay, Lankester Edwin Ray (vectorized by
T. Michael Keesey), Sharon Wegner-Larsen, Yan Wong, Lisa Byrne, Stanton
F. Fink (vectorized by T. Michael Keesey), Rebecca Groom (Based on Photo
by Andreas Trepte), Renata F. Martins, Crystal Maier, Francesco
“Architetto” Rollandin, Enoch Joseph Wetsy (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Joe Schneid (vectorized by
T. Michael Keesey), Óscar San−Isidro (vectorized by T. Michael Keesey),
FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey), Michael
Scroggie, Philippe Janvier (vectorized by T. Michael Keesey), Filip em,
Jose Carlos Arenas-Monroy, C. Camilo Julián-Caballero, Noah Schlottman,
Aviceda (vectorized by T. Michael Keesey), Joseph J. W. Sertich, Mark A.
Loewen, Robert Hering, Donovan Reginald Rosevear (vectorized by T.
Michael Keesey), Walter Vladimir, Mathieu Pélissié, Darren Naish
(vectorize by T. Michael Keesey), Manabu Bessho-Uehara, FunkMonk, Henry
Lydecker, , Jonathan Wells, Scott Reid, FJDegrange, Mario Quevedo, Tony
Ayling (vectorized by Milton Tan), Stemonitis (photography) and T.
Michael Keesey (vectorization), Martin Kevil, Pedro de Siracusa, Conty
(vectorized by T. Michael Keesey), Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Sherman F. Denton via
rawpixel.com (illustration) and Timothy J. Bartley (silhouette), Mali’o
Kodis, photograph by Cordell Expeditions at Cal Academy, Noah
Schlottman, photo from Casey Dunn, CNZdenek, Inessa Voet, Tess Linden,
Meliponicultor Itaymbere, Lukasiniho, Mathieu Basille, Obsidian Soul
(vectorized by T. Michael Keesey), Chris Hay, Griensteidl and T. Michael
Keesey, John Curtis (vectorized by T. Michael Keesey), Julio Garza, Jake
Warner, Noah Schlottman, photo by Martin V. Sørensen, Ellen Edmonson and
Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette), Beth
Reinke, Sarefo (vectorized by T. Michael Keesey), Agnello Picorelli,
Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization),
Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja,
Geoff Shaw, Aadx, NASA, T. Michael Keesey (vectorization); Yves Bousquet
(photography), Aleksey Nagovitsyn (vectorized by T. Michael Keesey),
Stacy Spensley (Modified), Mattia Menchetti, Francesco Veronesi
(vectorized by T. Michael Keesey), Craig Dylke, Mali’o Kodis, photograph
by G. Giribet, annaleeblysse, Tom Tarrant (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, New York Zoological
Society, Sebastian Stabinger, Armin Reindl, David Orr, JCGiron, Dmitry
Bogdanov, T. Michael Keesey (vectorization); Thorsten Assmann, Jörn
Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea
Matern, Anika Timm, and David W. Wrase (photography), Emily Jane
McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur.
Bibliographisches, Mercedes Yrayzoz (vectorized by T. Michael Keesey),
Scott Hartman, modified by T. Michael Keesey, Caio Bernardes, vectorized
by Zimices, Fritz Geller-Grimm (vectorized by T. Michael Keesey), Chris
Jennings (Risiatto), Jakovche, Zsoldos Márton (vectorized by T. Michael
Keesey), (unknown), Fernando Campos De Domenico, Marmelad, Robert Gay,
modifed from Olegivvit, Anna Willoughby, E. J. Van Nieukerken, A.
Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey), Joseph
Wolf, 1863 (vectorization by Dinah Challen), Jon Hill (Photo by
Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Mark Witton,
Ricardo N. Martinez & Oscar A. Alcober, DW Bapst, modified from Ishitani
et al. 2016, Emil Schmidt (vectorized by Maxime Dahirel), Anthony
Caravaggi, Chris A. Hamilton, Pearson Scott Foresman (vectorized by T.
Michael Keesey), Matt Dempsey, Ieuan Jones, Ewald Rübsamen, xgirouxb,
Heinrich Harder (vectorized by William Gearty), Matt Martyniuk
(vectorized by T. Michael Keesey), Archaeodontosaurus (vectorized by T.
Michael Keesey), Thibaut Brunet, Birgit Lang; original image by
virmisco.org, Lee Harding (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Matt Celeskey, Danny Cicchetti
(vectorized by T. Michael Keesey), Ekaterina Kopeykina (vectorized by T.
Michael Keesey), Cristian Osorio & Paula Carrera, Proyecto Carnivoros
Australes (www.carnivorosaustrales.org), Darius Nau, Ville-Veikko
Sinkkonen, Michael Scroggie, from original photograph by John Bettaso,
USFWS (original photograph in public domain)., Mariana Ruiz Villarreal,
Christina N. Hodson, Ben Liebeskind, Maxime Dahirel, Didier Descouens
(vectorized by T. Michael Keesey), Sam Fraser-Smith (vectorized by T.
Michael Keesey), Zachary Quigley, Yan Wong from wikipedia drawing (PD:
Pearson Scott Foresman), Martin R. Smith, Smokeybjb (vectorized by T.
Michael Keesey), Chloé Schmidt, Renato Santos, T. Michael Keesey (after
MPF), T. Michael Keesey (after Colin M. L. Burnett), nicubunu, Emily
Jane McTavish, Sergio A. Muñoz-Gómez, Riccardo Percudani, Dmitry
Bogdanov, vectorized by Zimices, Mike Hanson, Oren Peles / vectorized by
Yan Wong, Tony Ayling, Xavier Giroux-Bougard, Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, Scott Hartman (modified by
T. Michael Keesey), Andrew Farke and Joseph Sertich

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    734.011927 |    252.877685 | Dean Schnabel                                                                                                                                                                        |
|   2 |    223.494981 |    203.219067 | NA                                                                                                                                                                                   |
|   3 |    108.608976 |    434.581508 | Ferran Sayol                                                                                                                                                                         |
|   4 |    492.538079 |    482.200669 | Scott Hartman                                                                                                                                                                        |
|   5 |    831.242072 |    349.300500 | Steven Traver                                                                                                                                                                        |
|   6 |    454.402896 |    408.839862 | Pranav Iyer (grey ideas)                                                                                                                                                             |
|   7 |    305.903732 |    597.603563 | Zimices                                                                                                                                                                              |
|   8 |     63.590011 |    325.388400 | Jaime Headden                                                                                                                                                                        |
|   9 |    633.164660 |    491.593134 | Margot Michaud                                                                                                                                                                       |
|  10 |    847.680663 |    602.606884 | Matt Crook                                                                                                                                                                           |
|  11 |    639.530171 |    159.096173 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|  12 |    956.501356 |    732.897524 | Zimices                                                                                                                                                                              |
|  13 |    775.842186 |    489.281226 | T. Michael Keesey                                                                                                                                                                    |
|  14 |    694.322483 |    712.775202 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                                           |
|  15 |    430.963215 |     19.819917 | Carlos Cano-Barbacil                                                                                                                                                                 |
|  16 |    806.296843 |    133.516318 | Scott Hartman                                                                                                                                                                        |
|  17 |    459.416398 |    250.821051 | Jagged Fang Designs                                                                                                                                                                  |
|  18 |     71.908649 |    656.392717 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  19 |    758.422832 |     59.506748 | Zimices                                                                                                                                                                              |
|  20 |    511.418232 |    129.182356 | Sarah Werning                                                                                                                                                                        |
|  21 |    785.482884 |    786.897229 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
|  22 |    113.695991 |     74.849944 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  23 |    938.029083 |    241.059080 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                                     |
|  24 |    659.853111 |    364.419633 | Katie S. Collins                                                                                                                                                                     |
|  25 |    619.904634 |     61.046917 | Margot Michaud                                                                                                                                                                       |
|  26 |    272.197986 |     51.649882 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  27 |    270.013652 |    127.996289 | Rene Martin                                                                                                                                                                          |
|  28 |    960.944169 |    496.047038 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
|  29 |    478.638324 |    740.227817 | Steven Coombs                                                                                                                                                                        |
|  30 |    555.740284 |    628.465853 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  31 |    216.983037 |    347.240745 | Zimices                                                                                                                                                                              |
|  32 |    916.612318 |     65.333769 | Danielle Alba                                                                                                                                                                        |
|  33 |    925.012411 |    421.032568 | Christian A. Masnaghetti                                                                                                                                                             |
|  34 |    420.649634 |    162.566273 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                                       |
|  35 |     64.621655 |    122.891003 | Zimices                                                                                                                                                                              |
|  36 |    568.611201 |    698.860817 | Joanna Wolfe                                                                                                                                                                         |
|  37 |    219.587839 |    435.470263 | Steven Traver                                                                                                                                                                        |
|  38 |    358.679132 |     58.030100 | Rebecca Groom                                                                                                                                                                        |
|  39 |    116.803040 |    208.870516 | Margot Michaud                                                                                                                                                                       |
|  40 |    966.138431 |    345.289940 | Terpsichores                                                                                                                                                                         |
|  41 |    783.136312 |    706.398721 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                                    |
|  42 |    339.174676 |    725.187397 | Benjamint444                                                                                                                                                                         |
|  43 |    204.778710 |    741.167415 | Jagged Fang Designs                                                                                                                                                                  |
|  44 |    513.470985 |    520.209882 | Carlos Cano-Barbacil                                                                                                                                                                 |
|  45 |    351.273886 |    191.159192 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
|  46 |    674.955171 |    636.767272 | Margot Michaud                                                                                                                                                                       |
|  47 |    702.472846 |    563.134969 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
|  48 |    484.734379 |    334.794465 | T. Michael Keesey (after Monika Betley)                                                                                                                                              |
|  49 |    544.294908 |    427.627154 | Andrew A. Farke                                                                                                                                                                      |
|  50 |    958.518372 |    160.649187 | Markus A. Grohme                                                                                                                                                                     |
|  51 |    446.874302 |    774.752783 | Jagged Fang Designs                                                                                                                                                                  |
|  52 |    228.714512 |     18.708528 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  53 |    291.212240 |    475.472142 | Margot Michaud                                                                                                                                                                       |
|  54 |    856.934914 |    467.841400 | Matt Wilkins                                                                                                                                                                         |
|  55 |    125.466545 |    585.225170 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                                              |
|  56 |    586.866975 |    298.580501 | Matt Crook                                                                                                                                                                           |
|  57 |    960.604569 |    617.486084 | Birgit Lang                                                                                                                                                                          |
|  58 |    315.782957 |     94.774242 | Jagged Fang Designs                                                                                                                                                                  |
|  59 |    637.151952 |    744.263763 | Juan Carlos Jerí                                                                                                                                                                     |
|  60 |    136.402157 |     46.500986 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  61 |    143.627344 |    776.369013 | Tracy A. Heath                                                                                                                                                                       |
|  62 |     59.760986 |    479.631979 | Stuart Humphries                                                                                                                                                                     |
|  63 |    345.718550 |    308.778213 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
|  64 |    567.130098 |    563.090669 | Markus A. Grohme                                                                                                                                                                     |
|  65 |    936.726002 |    779.133922 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  66 |    124.504580 |    263.974173 | Jagged Fang Designs                                                                                                                                                                  |
|  67 |    803.925783 |    381.611226 | Andy Wilson                                                                                                                                                                          |
|  68 |     93.283942 |    712.425218 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                                         |
|  69 |    313.709946 |    156.671414 | Smokeybjb                                                                                                                                                                            |
|  70 |     31.222292 |    217.698535 | NA                                                                                                                                                                                   |
|  71 |     32.763413 |    551.826796 | Alex Slavenko                                                                                                                                                                        |
|  72 |     61.874994 |    738.488241 | Birgit Lang                                                                                                                                                                          |
|  73 |    863.542500 |     19.782074 | Caleb M. Brown                                                                                                                                                                       |
|  74 |     45.384707 |     26.073903 | Scott Hartman                                                                                                                                                                        |
|  75 |    119.806516 |    164.862013 | NA                                                                                                                                                                                   |
|  76 |    855.855312 |     67.120436 | Zimices                                                                                                                                                                              |
|  77 |    891.126305 |    316.859828 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                           |
|  78 |    721.227537 |     84.965746 | Margot Michaud                                                                                                                                                                       |
|  79 |    694.258022 |    775.023820 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                                            |
|  80 |    709.949248 |    432.356861 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  81 |    849.117795 |    755.128162 | Steven Traver                                                                                                                                                                        |
|  82 |    897.386818 |    382.930953 | T. Michael Keesey (after Monika Betley)                                                                                                                                              |
|  83 |    706.294281 |    595.603624 | Zimices                                                                                                                                                                              |
|  84 |    566.558974 |    782.636995 | Dean Schnabel                                                                                                                                                                        |
|  85 |   1000.155680 |    555.205021 | Mathilde Cordellier                                                                                                                                                                  |
|  86 |    971.111503 |    195.780872 | Harold N Eyster                                                                                                                                                                      |
|  87 |    927.134317 |    690.756820 | Andy Wilson                                                                                                                                                                          |
|  88 |    196.437521 |     86.456430 | Birgit Lang                                                                                                                                                                          |
|  89 |    370.202155 |    702.339660 | Chuanixn Yu                                                                                                                                                                          |
|  90 |    804.761182 |    453.459808 | Matt Crook                                                                                                                                                                           |
|  91 |    703.099065 |    323.012201 | Zimices                                                                                                                                                                              |
|  92 |    601.702461 |    590.806322 | Steven Traver                                                                                                                                                                        |
|  93 |    872.031599 |    263.072120 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
|  94 |    861.230555 |    193.528668 | Jagged Fang Designs                                                                                                                                                                  |
|  95 |    720.445228 |     19.433675 | Alex Slavenko                                                                                                                                                                        |
|  96 |    592.050168 |    675.450531 | Ignacio Contreras                                                                                                                                                                    |
|  97 |     16.331369 |    412.573739 | Matt Crook                                                                                                                                                                           |
|  98 |     36.392618 |    388.893853 | Cesar Julian                                                                                                                                                                         |
|  99 |    998.657421 |    255.920162 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 100 |    356.414024 |    492.059433 | Hugo Gruson                                                                                                                                                                          |
| 101 |    379.254658 |    474.481869 | Joanna Wolfe                                                                                                                                                                         |
| 102 |    187.108536 |    393.105326 | NA                                                                                                                                                                                   |
| 103 |    100.051984 |    345.549885 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 104 |   1000.501902 |    428.561890 | Matt Crook                                                                                                                                                                           |
| 105 |    876.698143 |    669.553725 | Margot Michaud                                                                                                                                                                       |
| 106 |    924.089123 |    362.069925 | Felix Vaux                                                                                                                                                                           |
| 107 |    388.467877 |    344.495705 | Iain Reid                                                                                                                                                                            |
| 108 |    492.601039 |     53.704935 | Ferran Sayol                                                                                                                                                                         |
| 109 |    173.640989 |    687.590144 | NA                                                                                                                                                                                   |
| 110 |    823.888434 |    111.145975 | Amanda Katzer                                                                                                                                                                        |
| 111 |    400.440821 |    674.103852 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 112 |    459.756494 |    294.989697 | Jack Mayer Wood                                                                                                                                                                      |
| 113 |     17.757103 |    472.285921 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 114 |    931.486382 |     13.323348 | Ferran Sayol                                                                                                                                                                         |
| 115 |    391.531776 |    697.297530 | Fernando Carezzano                                                                                                                                                                   |
| 116 |    734.415962 |    654.497401 | Matt Crook                                                                                                                                                                           |
| 117 |    129.114204 |    629.472168 | Steven Traver                                                                                                                                                                        |
| 118 |    655.107501 |    604.514597 | Shyamal                                                                                                                                                                              |
| 119 |    330.360903 |    440.891779 | Michelle Site                                                                                                                                                                        |
| 120 |     50.510541 |    764.389949 | Alex Slavenko                                                                                                                                                                        |
| 121 |    835.163979 |    311.110138 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 122 |    351.372105 |    123.836034 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 123 |    240.476238 |    771.743787 | Scott Hartman                                                                                                                                                                        |
| 124 |    119.917593 |    523.742364 | Zimices                                                                                                                                                                              |
| 125 |    246.266693 |    496.119469 | Matt Crook                                                                                                                                                                           |
| 126 |    923.022516 |     13.791239 | Gareth Monger                                                                                                                                                                        |
| 127 |    154.980164 |     14.619913 | Matt Crook                                                                                                                                                                           |
| 128 |    138.727766 |    792.391380 | Gareth Monger                                                                                                                                                                        |
| 129 |    584.844521 |    182.991897 | Christoph Schomburg                                                                                                                                                                  |
| 130 |    302.212762 |    401.265464 | Michelle Site                                                                                                                                                                        |
| 131 |    336.444308 |    506.433508 | Peileppe                                                                                                                                                                             |
| 132 |    612.668308 |    443.717193 | Blanco et al., 2014, vectorized by Zimices                                                                                                                                           |
| 133 |     51.462891 |    258.441518 | T. Michael Keesey (after Mauricio Antón)                                                                                                                                             |
| 134 |    971.710733 |    390.773634 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 135 |    418.816220 |    447.234223 | NA                                                                                                                                                                                   |
| 136 |    274.561717 |    715.804736 | Ingo Braasch                                                                                                                                                                         |
| 137 |    244.473824 |    100.050754 | Pete Buchholz                                                                                                                                                                        |
| 138 |    686.747525 |    722.945283 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 139 |    705.623195 |     16.564622 | Erika Schumacher                                                                                                                                                                     |
| 140 |    540.278014 |    223.655963 | Michele Tobias                                                                                                                                                                       |
| 141 |    315.305561 |    410.985860 | Renato de Carvalho Ferreira                                                                                                                                                          |
| 142 |    681.847529 |    113.847166 | Tracy A. Heath                                                                                                                                                                       |
| 143 |    451.492755 |     89.279694 | Katie S. Collins                                                                                                                                                                     |
| 144 |    774.586567 |    365.746042 | Gareth Monger                                                                                                                                                                        |
| 145 |    602.280237 |    775.374207 | Margot Michaud                                                                                                                                                                       |
| 146 |    905.089060 |    564.182075 | Birgit Lang                                                                                                                                                                          |
| 147 |     84.982996 |    281.119708 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 148 |    218.032395 |    640.084513 | Margot Michaud                                                                                                                                                                       |
| 149 |    323.987099 |    702.605939 | Zimices                                                                                                                                                                              |
| 150 |    973.343571 |    115.527312 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 151 |    139.866452 |    307.793951 | Tasman Dixon                                                                                                                                                                         |
| 152 |    873.810436 |    758.164667 | Chris huh                                                                                                                                                                            |
| 153 |    787.922845 |    106.264282 | Gareth Monger                                                                                                                                                                        |
| 154 |    489.491093 |    678.657746 | Tauana J. Cunha                                                                                                                                                                      |
| 155 |   1013.485447 |    266.628803 | Margot Michaud                                                                                                                                                                       |
| 156 |    185.658580 |    697.431596 | Emily Willoughby                                                                                                                                                                     |
| 157 |    647.591202 |    195.640125 | Andy Wilson                                                                                                                                                                          |
| 158 |    878.320964 |     55.028427 | Jagged Fang Designs                                                                                                                                                                  |
| 159 |    986.872856 |    257.603122 | Ferran Sayol                                                                                                                                                                         |
| 160 |    775.271802 |    545.028257 | Margot Michaud                                                                                                                                                                       |
| 161 |    388.061179 |    324.429225 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                                      |
| 162 |    497.490084 |    567.563147 | Neil Kelley                                                                                                                                                                          |
| 163 |   1012.018459 |    106.276688 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                             |
| 164 |    973.122133 |    214.347785 | Michelle Site                                                                                                                                                                        |
| 165 |    767.346026 |    100.800893 | Felix Vaux                                                                                                                                                                           |
| 166 |    530.604306 |     58.912157 | Maija Karala                                                                                                                                                                         |
| 167 |    741.560754 |    342.458587 | Matt Crook                                                                                                                                                                           |
| 168 |    661.508469 |    404.237364 | Taro Maeda                                                                                                                                                                           |
| 169 |   1013.249344 |    779.684503 | L. Shyamal                                                                                                                                                                           |
| 170 |    893.439295 |    272.344917 | T. Michael Keesey                                                                                                                                                                    |
| 171 |    811.235994 |    178.152569 | Kai R. Caspar                                                                                                                                                                        |
| 172 |    890.176515 |    549.238204 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                              |
| 173 |    812.767502 |    317.139470 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 174 |    623.340898 |    430.296909 | Mathew Stewart                                                                                                                                                                       |
| 175 |    920.116992 |    584.140468 | Becky Barnes                                                                                                                                                                         |
| 176 |    376.105236 |     93.646108 | Mason McNair                                                                                                                                                                         |
| 177 |    878.662432 |    173.708549 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                                              |
| 178 |    783.398538 |    635.768545 | Matt Crook                                                                                                                                                                           |
| 179 |    499.676259 |    218.616391 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 180 |    476.003845 |    651.556681 | Jiekun He                                                                                                                                                                            |
| 181 |   1001.084838 |     11.968765 | Tyler Greenfield and Scott Hartman                                                                                                                                                   |
| 182 |    101.811479 |    555.898278 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 183 |    987.824088 |     74.339902 | Matt Crook                                                                                                                                                                           |
| 184 |    684.441718 |      7.345557 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                         |
| 185 |    776.830789 |    571.281620 | Ignacio Contreras                                                                                                                                                                    |
| 186 |    372.176240 |    462.332583 | Margot Michaud                                                                                                                                                                       |
| 187 |     92.960701 |    546.655604 | Cristopher Silva                                                                                                                                                                     |
| 188 |    162.237445 |    272.753074 | Tracy A. Heath                                                                                                                                                                       |
| 189 |    956.210673 |    694.953358 | Jagged Fang Designs                                                                                                                                                                  |
| 190 |    374.928453 |    225.828124 | Matt Hayes                                                                                                                                                                           |
| 191 |    840.709015 |     50.317923 | Bryan Carstens                                                                                                                                                                       |
| 192 |    600.672052 |     96.889011 | Erika Schumacher                                                                                                                                                                     |
| 193 |    185.707792 |    657.922921 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                                             |
| 194 |    123.585452 |     24.736901 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
| 195 |    729.257901 |    104.920288 | Tauana J. Cunha                                                                                                                                                                      |
| 196 |    776.630464 |    556.471192 | Scott Hartman                                                                                                                                                                        |
| 197 |    186.501284 |    410.001615 | Collin Gross                                                                                                                                                                         |
| 198 |    710.336383 |    733.207553 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 199 |   1007.002672 |    307.474133 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                                    |
| 200 |    705.809280 |    643.427560 | Zimices                                                                                                                                                                              |
| 201 |    658.017404 |    719.537463 | Alexandre Vong                                                                                                                                                                       |
| 202 |    827.919572 |     89.469843 | Zimices                                                                                                                                                                              |
| 203 |    448.026612 |    515.518869 | T. Michael Keesey                                                                                                                                                                    |
| 204 |    867.354004 |     43.684121 | Oscar Sanisidro                                                                                                                                                                      |
| 205 |     55.492768 |    784.748192 | Zimices                                                                                                                                                                              |
| 206 |    311.175507 |     41.628241 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 207 |    737.775463 |    422.244346 | Michael P. Taylor                                                                                                                                                                    |
| 208 |     39.221744 |    791.780368 | Kamil S. Jaron                                                                                                                                                                       |
| 209 |    891.135226 |    538.065460 | V. Deepak                                                                                                                                                                            |
| 210 |    571.863181 |    429.732782 | \[unknown\]                                                                                                                                                                          |
| 211 |    152.344255 |    656.525446 | Ingo Braasch                                                                                                                                                                         |
| 212 |    884.713340 |    693.225994 | Ferran Sayol                                                                                                                                                                         |
| 213 |    316.468428 |    786.875124 | Zimices                                                                                                                                                                              |
| 214 |    713.770436 |    505.231242 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 215 |    613.323372 |    220.756654 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 216 |    927.841015 |    548.786566 | Matt Crook                                                                                                                                                                           |
| 217 |    610.040744 |     15.471812 | Michele M Tobias                                                                                                                                                                     |
| 218 |    249.554847 |    364.245829 | Liftarn                                                                                                                                                                              |
| 219 |    376.792274 |    124.708126 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 220 |    560.000332 |    207.637781 | Jaime Headden                                                                                                                                                                        |
| 221 |    771.514365 |     81.833596 | Neil Kelley                                                                                                                                                                          |
| 222 |    187.758730 |    637.463565 | Chase Brownstein                                                                                                                                                                     |
| 223 |    194.178791 |    262.836493 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 224 |    650.703584 |    294.889376 | Matt Crook                                                                                                                                                                           |
| 225 |    702.227884 |    414.330183 | Steven Traver                                                                                                                                                                        |
| 226 |    764.374295 |    325.920604 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 227 |    571.473117 |    601.641660 | Scott Hartman                                                                                                                                                                        |
| 228 |    151.590003 |    667.488067 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                                          |
| 229 |    683.476821 |    761.988466 | Zimices                                                                                                                                                                              |
| 230 |    932.804596 |    645.792558 | NA                                                                                                                                                                                   |
| 231 |    516.978698 |    452.879945 | Zimices                                                                                                                                                                              |
| 232 |    847.329996 |    182.125940 | Ingo Braasch                                                                                                                                                                         |
| 233 |    828.144211 |    523.661925 | Ferran Sayol                                                                                                                                                                         |
| 234 |    257.360493 |    765.578202 | Collin Gross                                                                                                                                                                         |
| 235 |    434.132333 |    341.944455 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                           |
| 236 |    478.587554 |     47.315379 | Gareth Monger                                                                                                                                                                        |
| 237 |    255.535702 |    709.075438 | Matt Crook                                                                                                                                                                           |
| 238 |    109.799668 |    515.999102 | T. Michael Keesey                                                                                                                                                                    |
| 239 |     41.987442 |     60.797048 | Jack Mayer Wood                                                                                                                                                                      |
| 240 |    136.885034 |    612.749984 | Birgit Lang                                                                                                                                                                          |
| 241 |    586.102031 |    706.081830 | SecretJellyMan                                                                                                                                                                       |
| 242 |    206.600951 |    656.492692 | Andrew A. Farke                                                                                                                                                                      |
| 243 |    852.234662 |    363.373648 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                       |
| 244 |     90.889101 |    622.601785 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 245 |    703.064360 |    625.322189 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 246 |    207.314640 |    472.044453 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 247 |    536.840393 |    588.299276 | NA                                                                                                                                                                                   |
| 248 |    206.143974 |    688.937453 | Matt Crook                                                                                                                                                                           |
| 249 |    733.982775 |    169.957657 | Ludwik Gąsiorowski                                                                                                                                                                   |
| 250 |    682.929766 |    308.044262 | Emily Willoughby                                                                                                                                                                     |
| 251 |    152.667997 |    637.203687 | Kent Elson Sorgon                                                                                                                                                                    |
| 252 |    982.702566 |     25.232661 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 253 |    692.620817 |    527.544662 | Samanta Orellana                                                                                                                                                                     |
| 254 |    455.855355 |     64.331780 | Bryan Carstens                                                                                                                                                                       |
| 255 |     89.895109 |    136.720400 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                         |
| 256 |    737.502418 |    374.026730 | Zimices                                                                                                                                                                              |
| 257 |    165.463167 |    320.753330 | Sarah Werning                                                                                                                                                                        |
| 258 |    992.543050 |    223.341955 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                                |
| 259 |    796.894945 |     23.289089 | Arthur S. Brum                                                                                                                                                                       |
| 260 |   1007.326673 |     45.616254 | Matt Martyniuk                                                                                                                                                                       |
| 261 |    987.461075 |     92.817252 | Dinah Challen                                                                                                                                                                        |
| 262 |    785.438650 |    441.504228 | Robert Gay                                                                                                                                                                           |
| 263 |     21.398192 |     36.389688 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 264 |    813.564918 |    778.107393 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 265 |    939.520523 |    697.181011 | Felix Vaux                                                                                                                                                                           |
| 266 |    705.356139 |    517.454073 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 267 |    342.089198 |    246.140272 | NA                                                                                                                                                                                   |
| 268 |   1017.841623 |    205.308922 | Yan Wong                                                                                                                                                                             |
| 269 |    167.491024 |     68.157000 | T. Michael Keesey                                                                                                                                                                    |
| 270 |    492.487810 |    540.436153 | Lisa Byrne                                                                                                                                                                           |
| 271 |    842.104711 |    530.171109 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 272 |    313.675998 |    424.700183 | Gareth Monger                                                                                                                                                                        |
| 273 |    719.167039 |    157.148834 | Matt Crook                                                                                                                                                                           |
| 274 |    767.949004 |    581.948413 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 275 |    814.769285 |    483.214122 | Andy Wilson                                                                                                                                                                          |
| 276 |   1002.637399 |    589.006545 | Chris huh                                                                                                                                                                            |
| 277 |    672.503264 |    321.034061 | Zimices                                                                                                                                                                              |
| 278 |    236.384007 |    620.982063 | Kamil S. Jaron                                                                                                                                                                       |
| 279 |    115.615597 |    336.026759 | T. Michael Keesey                                                                                                                                                                    |
| 280 |     46.783996 |    590.016883 | Taro Maeda                                                                                                                                                                           |
| 281 |   1007.264504 |    643.974279 | Jagged Fang Designs                                                                                                                                                                  |
| 282 |    541.560304 |    777.756276 | Ferran Sayol                                                                                                                                                                         |
| 283 |    339.552244 |    260.596985 | Jaime Headden                                                                                                                                                                        |
| 284 |    543.211048 |    506.709787 | Gareth Monger                                                                                                                                                                        |
| 285 |    763.875935 |    349.834252 | Gareth Monger                                                                                                                                                                        |
| 286 |    984.260152 |    405.371495 | NA                                                                                                                                                                                   |
| 287 |    907.648404 |    542.978607 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                                     |
| 288 |    908.471593 |    122.961930 | Renata F. Martins                                                                                                                                                                    |
| 289 |    517.696753 |    212.188907 | Crystal Maier                                                                                                                                                                        |
| 290 |    841.832140 |    224.529747 | Jagged Fang Designs                                                                                                                                                                  |
| 291 |     15.913182 |    486.675560 | NA                                                                                                                                                                                   |
| 292 |    722.402442 |    346.020284 | Francesco “Architetto” Rollandin                                                                                                                                                     |
| 293 |    459.621750 |    446.465081 | Ignacio Contreras                                                                                                                                                                    |
| 294 |   1003.263471 |    328.846753 | T. Michael Keesey                                                                                                                                                                    |
| 295 |    259.676138 |    272.520243 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 296 |    100.835639 |    372.503462 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                        |
| 297 |    938.816284 |    333.295050 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                                   |
| 298 |      6.835449 |    328.082116 | Margot Michaud                                                                                                                                                                       |
| 299 |    525.393504 |    723.164502 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                                            |
| 300 |    339.840810 |    415.087567 | Ferran Sayol                                                                                                                                                                         |
| 301 |     36.822271 |    460.143612 | Tasman Dixon                                                                                                                                                                         |
| 302 |    400.839515 |    145.018195 | Michael Scroggie                                                                                                                                                                     |
| 303 |    943.050864 |    188.254851 | Margot Michaud                                                                                                                                                                       |
| 304 |    753.727398 |    178.281578 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 305 |    400.913627 |     85.198744 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 306 |    642.039510 |    572.278687 | Tauana J. Cunha                                                                                                                                                                      |
| 307 |    266.375927 |    296.844985 | Kamil S. Jaron                                                                                                                                                                       |
| 308 |    403.395363 |     69.955574 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 309 |    724.020250 |    637.685496 | Filip em                                                                                                                                                                             |
| 310 |    626.745138 |    120.267522 | Matt Crook                                                                                                                                                                           |
| 311 |     56.711092 |     43.903588 | Gareth Monger                                                                                                                                                                        |
| 312 |    872.566393 |    749.902926 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                                   |
| 313 |    785.521468 |    416.669286 | Margot Michaud                                                                                                                                                                       |
| 314 |    803.149426 |     87.511600 | Michael Scroggie                                                                                                                                                                     |
| 315 |    902.559686 |     40.940629 | Ferran Sayol                                                                                                                                                                         |
| 316 |    918.883607 |    316.072561 | Steven Traver                                                                                                                                                                        |
| 317 |    838.384143 |    728.750830 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 318 |   1008.321987 |    660.459588 | Tasman Dixon                                                                                                                                                                         |
| 319 |    863.693109 |    308.771673 | Andy Wilson                                                                                                                                                                          |
| 320 |    678.162790 |     78.043106 | NA                                                                                                                                                                                   |
| 321 |    192.735277 |     63.714782 | Andy Wilson                                                                                                                                                                          |
| 322 |    242.040953 |    379.770701 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 323 |    956.010754 |    402.135475 | Jagged Fang Designs                                                                                                                                                                  |
| 324 |    463.779085 |    760.962181 | Jiekun He                                                                                                                                                                            |
| 325 |    167.529630 |    705.677475 | Noah Schlottman                                                                                                                                                                      |
| 326 |    750.515259 |    107.764252 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                                            |
| 327 |    539.441009 |    468.770452 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                                 |
| 328 |    338.493726 |    145.879235 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 329 |    502.210583 |    502.893835 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 330 |    894.004992 |    474.323231 | Zimices                                                                                                                                                                              |
| 331 |    639.109413 |    787.615149 | Gareth Monger                                                                                                                                                                        |
| 332 |    631.179799 |    601.275593 | Robert Hering                                                                                                                                                                        |
| 333 |    642.844178 |    433.499655 | Matt Crook                                                                                                                                                                           |
| 334 |     53.832193 |    286.831685 | Ferran Sayol                                                                                                                                                                         |
| 335 |    377.750954 |    483.188365 | Chris huh                                                                                                                                                                            |
| 336 |    645.102330 |    318.071410 | Jagged Fang Designs                                                                                                                                                                  |
| 337 |    688.225104 |    432.269078 | Zimices                                                                                                                                                                              |
| 338 |    249.567148 |    720.992746 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                                                          |
| 339 |    544.384245 |    404.601602 | Chase Brownstein                                                                                                                                                                     |
| 340 |    232.220695 |     94.992187 | Walter Vladimir                                                                                                                                                                      |
| 341 |    824.327874 |    159.738869 | Mathieu Pélissié                                                                                                                                                                     |
| 342 |     25.935200 |    702.199139 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 343 |    428.541380 |    128.206283 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 344 |      8.072254 |    301.564751 | Gareth Monger                                                                                                                                                                        |
| 345 |    913.526572 |    332.898341 | Gareth Monger                                                                                                                                                                        |
| 346 |     47.237184 |      9.592228 | Matt Crook                                                                                                                                                                           |
| 347 |    334.722750 |    685.601779 | FunkMonk                                                                                                                                                                             |
| 348 |     48.836212 |    151.351237 | Steven Traver                                                                                                                                                                        |
| 349 |    732.789240 |    186.770399 | Birgit Lang                                                                                                                                                                          |
| 350 |    319.631624 |    660.240749 | Christoph Schomburg                                                                                                                                                                  |
| 351 |     16.100556 |    607.358835 | Margot Michaud                                                                                                                                                                       |
| 352 |    258.964446 |    284.667588 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 353 |    715.942605 |    481.403903 | Henry Lydecker                                                                                                                                                                       |
| 354 |    586.074202 |     12.054719 | L. Shyamal                                                                                                                                                                           |
| 355 |    473.222186 |    642.144204 | Dean Schnabel                                                                                                                                                                        |
| 356 |    479.630120 |    693.552360 | NA                                                                                                                                                                                   |
| 357 |     14.245561 |    690.254648 | Andy Wilson                                                                                                                                                                          |
| 358 |    553.845607 |    719.596471 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 359 |    637.636233 |    587.407454 | Matt Crook                                                                                                                                                                           |
| 360 |    641.437074 |    127.327190 | Dean Schnabel                                                                                                                                                                        |
| 361 |     14.870242 |    648.461588 | Sarah Werning                                                                                                                                                                        |
| 362 |    787.788168 |    527.015832 |                                                                                                                                                                                      |
| 363 |     11.165916 |    673.690192 | Sarah Werning                                                                                                                                                                        |
| 364 |    201.204401 |    131.707603 | Jonathan Wells                                                                                                                                                                       |
| 365 |    525.738887 |     36.576250 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 366 |    185.989678 |    607.160161 | NA                                                                                                                                                                                   |
| 367 |    365.815758 |    177.711364 | Matt Crook                                                                                                                                                                           |
| 368 |    553.300326 |    330.688808 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 369 |    394.804688 |    507.530176 | Gareth Monger                                                                                                                                                                        |
| 370 |     10.528899 |    174.266257 | Margot Michaud                                                                                                                                                                       |
| 371 |    721.283831 |    595.610440 | Matt Crook                                                                                                                                                                           |
| 372 |     71.483170 |     41.162370 | Scott Reid                                                                                                                                                                           |
| 373 |    517.271699 |    400.283343 | Matt Martyniuk                                                                                                                                                                       |
| 374 |    100.980007 |     25.182284 | FJDegrange                                                                                                                                                                           |
| 375 |    145.353410 |    357.345389 | Tasman Dixon                                                                                                                                                                         |
| 376 |    187.878123 |    465.909152 | Andy Wilson                                                                                                                                                                          |
| 377 |    136.630509 |      9.391544 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 378 |     49.634515 |     82.940552 | Margot Michaud                                                                                                                                                                       |
| 379 |    106.736891 |    146.982401 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 380 |    224.786689 |    789.448868 | Mario Quevedo                                                                                                                                                                        |
| 381 |    587.451884 |    789.519571 | Jack Mayer Wood                                                                                                                                                                      |
| 382 |     94.833268 |    506.394173 | NA                                                                                                                                                                                   |
| 383 |     34.783234 |     74.126075 | Birgit Lang                                                                                                                                                                          |
| 384 |    284.200369 |    497.589163 | Matt Crook                                                                                                                                                                           |
| 385 |    751.970853 |    377.309032 | T. Michael Keesey                                                                                                                                                                    |
| 386 |    876.908187 |    385.788806 | Steven Coombs                                                                                                                                                                        |
| 387 |    357.526437 |     23.214371 | T. Michael Keesey                                                                                                                                                                    |
| 388 |    358.691208 |    359.482008 | NA                                                                                                                                                                                   |
| 389 |    795.445913 |    771.588375 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                               |
| 390 |    836.640044 |     35.036544 | Zimices                                                                                                                                                                              |
| 391 |    666.148069 |    121.748744 | Michelle Site                                                                                                                                                                        |
| 392 |    871.650813 |    779.229900 | Kamil S. Jaron                                                                                                                                                                       |
| 393 |    573.586636 |    225.518921 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 394 |    882.744690 |    125.707619 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 395 |     26.884384 |    668.691667 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                                           |
| 396 |    643.862114 |    772.390844 | Steven Traver                                                                                                                                                                        |
| 397 |    502.492665 |    775.896790 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 398 |    347.938346 |    168.678180 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 399 |     14.821508 |    435.066489 | Matt Crook                                                                                                                                                                           |
| 400 |    979.153823 |    787.744664 | Markus A. Grohme                                                                                                                                                                     |
| 401 |    674.130693 |    645.649343 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 402 |    647.723099 |     19.560011 | Margot Michaud                                                                                                                                                                       |
| 403 |     81.264088 |    557.398415 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 404 |     56.913668 |     33.098321 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 405 |    665.714022 |    678.848151 | Martin Kevil                                                                                                                                                                         |
| 406 |    934.135579 |    129.706682 | Ferran Sayol                                                                                                                                                                         |
| 407 |    327.399613 |    269.601232 | Chris huh                                                                                                                                                                            |
| 408 |    154.504093 |    418.769167 | Pedro de Siracusa                                                                                                                                                                    |
| 409 |    844.631392 |    155.090880 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 410 |    514.387510 |    760.242555 | NA                                                                                                                                                                                   |
| 411 |    209.529224 |     43.984697 | Margot Michaud                                                                                                                                                                       |
| 412 |    879.994948 |    440.447143 | Ferran Sayol                                                                                                                                                                         |
| 413 |    751.254528 |    593.871649 | Matt Crook                                                                                                                                                                           |
| 414 |    326.245470 |    411.968849 | Matt Crook                                                                                                                                                                           |
| 415 |    878.344833 |    180.072278 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 416 |     31.466701 |    526.125496 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 417 |    736.693966 |    606.145843 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                                |
| 418 |    884.038391 |    163.215102 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                                       |
| 419 |    623.992508 |    542.544214 | Matt Crook                                                                                                                                                                           |
| 420 |    895.810349 |    446.530594 | FJDegrange                                                                                                                                                                           |
| 421 |    476.274281 |    621.486509 | Andy Wilson                                                                                                                                                                          |
| 422 |    211.132968 |    597.324515 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                                              |
| 423 |    672.347493 |    724.526871 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 424 |    783.013065 |      5.878607 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 425 |    703.332870 |    113.942926 | Matt Crook                                                                                                                                                                           |
| 426 |     75.219262 |    305.403604 | Zimices                                                                                                                                                                              |
| 427 |     28.946400 |    328.970275 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                        |
| 428 |    552.266330 |     85.631620 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 429 |    578.386352 |    502.310490 | CNZdenek                                                                                                                                                                             |
| 430 |    730.448449 |    404.178021 | Scott Hartman                                                                                                                                                                        |
| 431 |    117.360979 |    461.461035 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                         |
| 432 |    323.090333 |    108.229584 | Jagged Fang Designs                                                                                                                                                                  |
| 433 |    354.612402 |    416.447741 | Inessa Voet                                                                                                                                                                          |
| 434 |     13.105356 |    537.107912 | Tess Linden                                                                                                                                                                          |
| 435 |     74.268922 |    383.968087 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 436 |   1017.455058 |    139.759452 | Meliponicultor Itaymbere                                                                                                                                                             |
| 437 |    207.114527 |    394.711661 | NA                                                                                                                                                                                   |
| 438 |    728.299445 |    199.074353 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 439 |    989.742372 |    139.977162 | Lukasiniho                                                                                                                                                                           |
| 440 |    668.835696 |    294.296082 | Mathieu Basille                                                                                                                                                                      |
| 441 |    407.239592 |    791.326284 | Matt Crook                                                                                                                                                                           |
| 442 |    563.372591 |    464.144295 | Matt Crook                                                                                                                                                                           |
| 443 |    420.429548 |    293.151396 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 444 |    230.064587 |    113.346519 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 445 |    460.509292 |    432.335590 | Chris Hay                                                                                                                                                                            |
| 446 |    639.492997 |    675.854460 | Robert Hering                                                                                                                                                                        |
| 447 |    773.426186 |    606.677199 | Ferran Sayol                                                                                                                                                                         |
| 448 |    303.395633 |     13.784314 | Zimices                                                                                                                                                                              |
| 449 |    753.043340 |    605.894727 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 450 |    445.649353 |    467.604195 | FunkMonk                                                                                                                                                                             |
| 451 |    984.408398 |    109.239914 | Kai R. Caspar                                                                                                                                                                        |
| 452 |    706.468902 |    186.773258 | Stuart Humphries                                                                                                                                                                     |
| 453 |    413.173602 |    168.989599 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 454 |    600.682217 |    663.316705 | NA                                                                                                                                                                                   |
| 455 |    588.121026 |    458.283862 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 456 |    977.026789 |     59.541849 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 457 |    733.306292 |    436.808218 | Julio Garza                                                                                                                                                                          |
| 458 |    482.748764 |    284.798605 | Zimices                                                                                                                                                                              |
| 459 |    150.097998 |    319.471167 | Lukasiniho                                                                                                                                                                           |
| 460 |    993.426724 |    598.988392 | Margot Michaud                                                                                                                                                                       |
| 461 |    149.986342 |    482.618828 | Jake Warner                                                                                                                                                                          |
| 462 |    110.473326 |    123.905234 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
| 463 |    328.608433 |     78.502785 | Shyamal                                                                                                                                                                              |
| 464 |    408.394019 |     75.981804 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                                    |
| 465 |    590.654464 |    211.357593 | NA                                                                                                                                                                                   |
| 466 |    854.314173 |    695.011927 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 467 |    762.439666 |      7.405524 | Margot Michaud                                                                                                                                                                       |
| 468 |    979.658939 |    428.108301 | NA                                                                                                                                                                                   |
| 469 |    279.079256 |    318.253491 | Harold N Eyster                                                                                                                                                                      |
| 470 |    111.254027 |    311.693966 | Beth Reinke                                                                                                                                                                          |
| 471 |    156.371288 |    405.616054 | Chris huh                                                                                                                                                                            |
| 472 |    722.842865 |    415.293569 | Chris huh                                                                                                                                                                            |
| 473 |    257.430825 |    100.012187 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                                             |
| 474 |    845.560000 |     93.734461 | Andy Wilson                                                                                                                                                                          |
| 475 |    864.838283 |    526.417125 | Agnello Picorelli                                                                                                                                                                    |
| 476 |    242.597227 |    284.795050 | Tasman Dixon                                                                                                                                                                         |
| 477 |    752.017015 |    412.119242 | Matt Crook                                                                                                                                                                           |
| 478 |    673.322139 |    784.558383 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                                              |
| 479 |    194.535993 |    302.776940 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                                   |
| 480 |    226.560886 |    602.207898 | Zimices                                                                                                                                                                              |
| 481 |    185.086968 |    620.950738 | Matt Crook                                                                                                                                                                           |
| 482 |    847.249158 |    705.743906 | Mathilde Cordellier                                                                                                                                                                  |
| 483 |    664.784969 |    436.071699 | Geoff Shaw                                                                                                                                                                           |
| 484 |    545.034092 |     42.326117 | Matt Crook                                                                                                                                                                           |
| 485 |    558.008751 |     62.020919 | Aadx                                                                                                                                                                                 |
| 486 |    375.856749 |    738.458869 | NASA                                                                                                                                                                                 |
| 487 |    680.399568 |    590.531805 | Matt Crook                                                                                                                                                                           |
| 488 |    868.226633 |    203.807393 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                                       |
| 489 |    933.199246 |    796.819329 | Walter Vladimir                                                                                                                                                                      |
| 490 |    564.538648 |     16.504792 | Felix Vaux                                                                                                                                                                           |
| 491 |    701.110395 |    493.461175 | Michelle Site                                                                                                                                                                        |
| 492 |    947.893415 |    110.256501 | Noah Schlottman                                                                                                                                                                      |
| 493 |    848.484394 |    517.857173 | NA                                                                                                                                                                                   |
| 494 |    969.457458 |    678.405415 | Matt Crook                                                                                                                                                                           |
| 495 |   1008.337581 |    199.910845 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 496 |    342.315425 |    705.299335 | Zimices                                                                                                                                                                              |
| 497 |    829.432992 |    491.435802 | Margot Michaud                                                                                                                                                                       |
| 498 |    281.773929 |    789.256576 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                                 |
| 499 |    568.818595 |     96.961713 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 500 |    574.040549 |    160.687752 | Chris huh                                                                                                                                                                            |
| 501 |    903.404295 |    353.067833 | Stacy Spensley (Modified)                                                                                                                                                            |
| 502 |    863.057543 |    223.412787 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 503 |    247.745763 |    788.313864 | Oscar Sanisidro                                                                                                                                                                      |
| 504 |     66.962939 |    628.413454 | Benjamint444                                                                                                                                                                         |
| 505 |    630.146698 |    693.496491 | Mattia Menchetti                                                                                                                                                                     |
| 506 |    715.953523 |    208.796652 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 507 |    716.424836 |    530.810823 | Gareth Monger                                                                                                                                                                        |
| 508 |    720.730598 |    330.608426 | Ignacio Contreras                                                                                                                                                                    |
| 509 |    677.808133 |    418.665627 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                                 |
| 510 |    415.599371 |     88.112178 | Matt Crook                                                                                                                                                                           |
| 511 |    791.861391 |    352.927383 | Collin Gross                                                                                                                                                                         |
| 512 |   1000.081034 |    119.451319 | Matt Crook                                                                                                                                                                           |
| 513 |    408.085247 |    425.119587 | Jagged Fang Designs                                                                                                                                                                  |
| 514 |     60.809579 |     15.144276 | Craig Dylke                                                                                                                                                                          |
| 515 |     55.179271 |    544.684770 | Scott Hartman                                                                                                                                                                        |
| 516 |    184.560380 |    650.174528 | Maija Karala                                                                                                                                                                         |
| 517 |    687.443754 |    102.471519 | Margot Michaud                                                                                                                                                                       |
| 518 |    258.871677 |    346.676116 | Steven Traver                                                                                                                                                                        |
| 519 |    110.769926 |    527.533244 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 520 |    797.829879 |    167.073937 | Harold N Eyster                                                                                                                                                                      |
| 521 |    206.573604 |    635.297689 | Matt Crook                                                                                                                                                                           |
| 522 |    856.166168 |    290.450696 | annaleeblysse                                                                                                                                                                        |
| 523 |    677.592735 |    221.146584 | Scott Hartman                                                                                                                                                                        |
| 524 |     72.494354 |    217.405692 | Margot Michaud                                                                                                                                                                       |
| 525 |    202.774702 |    650.006117 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 526 |    756.125411 |     92.014065 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 527 |   1012.522164 |    447.821973 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 528 |    508.757599 |    548.748086 | Ignacio Contreras                                                                                                                                                                    |
| 529 |    634.984805 |     10.277766 | New York Zoological Society                                                                                                                                                          |
| 530 |    968.241075 |    175.441383 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 531 |   1015.664736 |      2.804653 | Dean Schnabel                                                                                                                                                                        |
| 532 |    664.822442 |    791.588873 | Jagged Fang Designs                                                                                                                                                                  |
| 533 |    921.539653 |    745.666373 | Kent Elson Sorgon                                                                                                                                                                    |
| 534 |    446.233671 |    458.174781 | Tasman Dixon                                                                                                                                                                         |
| 535 |    976.960447 |     40.307751 | Sebastian Stabinger                                                                                                                                                                  |
| 536 |    135.779303 |    280.048142 | Matt Crook                                                                                                                                                                           |
| 537 |     46.883841 |    404.606676 | Kamil S. Jaron                                                                                                                                                                       |
| 538 |    723.473262 |    466.970739 | Jaime Headden                                                                                                                                                                        |
| 539 |    621.151332 |    664.651948 | Matt Crook                                                                                                                                                                           |
| 540 |    298.558844 |    776.817899 | Zimices                                                                                                                                                                              |
| 541 |    914.262040 |    597.882326 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 542 |    419.820703 |    153.643254 | T. Michael Keesey                                                                                                                                                                    |
| 543 |    571.441118 |    445.718338 | Matt Crook                                                                                                                                                                           |
| 544 |    869.204854 |    149.196530 | Armin Reindl                                                                                                                                                                         |
| 545 |    202.683674 |    621.881492 | Zimices                                                                                                                                                                              |
| 546 |    593.396263 |    413.803086 | Matt Crook                                                                                                                                                                           |
| 547 |    334.879202 |    672.619444 | Ferran Sayol                                                                                                                                                                         |
| 548 |    801.104711 |     14.946286 | David Orr                                                                                                                                                                            |
| 549 |    851.001664 |    248.396494 | JCGiron                                                                                                                                                                              |
| 550 |     41.147408 |    288.984783 | Tasman Dixon                                                                                                                                                                         |
| 551 |    529.350891 |    791.468261 | Dmitry Bogdanov                                                                                                                                                                      |
| 552 |    710.436976 |    705.637604 | Zimices                                                                                                                                                                              |
| 553 |    421.136342 |     45.960877 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 554 |   1013.385247 |    184.634700 | Chris huh                                                                                                                                                                            |
| 555 |   1004.272601 |    362.758228 | NA                                                                                                                                                                                   |
| 556 |    600.923341 |    237.049170 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 557 |    177.161411 |    273.047149 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                                       |
| 558 |    350.955744 |    653.287852 | Steven Traver                                                                                                                                                                        |
| 559 |    218.380132 |    480.618091 | Ferran Sayol                                                                                                                                                                         |
| 560 |    647.003712 |    459.324568 | Jaime Headden                                                                                                                                                                        |
| 561 |    580.652437 |    118.122879 | Jagged Fang Designs                                                                                                                                                                  |
| 562 |    153.606962 |    169.964476 | Matt Crook                                                                                                                                                                           |
| 563 |    260.238937 |    784.412552 | NA                                                                                                                                                                                   |
| 564 |    826.975037 |    753.864725 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                                   |
| 565 |    686.151702 |     65.451757 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 566 |    702.944616 |    478.124295 | Tasman Dixon                                                                                                                                                                         |
| 567 |    429.026041 |    176.083264 | Hugo Gruson                                                                                                                                                                          |
| 568 |    160.839740 |    288.435101 | FunkMonk                                                                                                                                                                             |
| 569 |     11.657823 |    661.085863 | Margot Michaud                                                                                                                                                                       |
| 570 |    238.440987 |    296.512603 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
| 571 |    225.717874 |    662.291801 | T. Michael Keesey                                                                                                                                                                    |
| 572 |    236.204720 |    144.113905 | Margot Michaud                                                                                                                                                                       |
| 573 |    328.187170 |    713.852757 | Cesar Julian                                                                                                                                                                         |
| 574 |    394.647610 |     96.223614 | NA                                                                                                                                                                                   |
| 575 |    474.660351 |    196.686806 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 576 |      8.012288 |    518.807031 | NA                                                                                                                                                                                   |
| 577 |    381.328806 |      4.514379 | Amanda Katzer                                                                                                                                                                        |
| 578 |    470.174522 |     38.304157 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 579 |    914.383457 |    639.166595 | Michael Scroggie                                                                                                                                                                     |
| 580 |      7.705369 |    742.562337 | Margot Michaud                                                                                                                                                                       |
| 581 |     35.073063 |     45.516069 | NA                                                                                                                                                                                   |
| 582 |    412.317152 |    317.797805 | Chase Brownstein                                                                                                                                                                     |
| 583 |    120.413804 |    249.769877 | Markus A. Grohme                                                                                                                                                                     |
| 584 |    196.599148 |    366.795292 | Margot Michaud                                                                                                                                                                       |
| 585 |      9.988081 |    451.368570 | Zimices                                                                                                                                                                              |
| 586 |     20.289320 |    311.696849 | NA                                                                                                                                                                                   |
| 587 |    555.790600 |    193.432065 | Gareth Monger                                                                                                                                                                        |
| 588 |    346.079561 |    643.089565 | Caio Bernardes, vectorized by Zimices                                                                                                                                                |
| 589 |     81.974605 |    389.807883 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                                 |
| 590 |    990.440930 |    333.838214 | Chris Jennings (Risiatto)                                                                                                                                                            |
| 591 |    585.756028 |    765.935839 | NA                                                                                                                                                                                   |
| 592 |     16.800856 |    715.961465 | Jakovche                                                                                                                                                                             |
| 593 |   1002.804239 |    676.479989 | Zimices                                                                                                                                                                              |
| 594 |    707.845239 |    177.101314 | Andy Wilson                                                                                                                                                                          |
| 595 |    687.713294 |     34.566032 | Zimices                                                                                                                                                                              |
| 596 |    729.645930 |    399.470313 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 597 |     71.091069 |    163.568967 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 598 |     21.508163 |    296.889998 | Ferran Sayol                                                                                                                                                                         |
| 599 |    826.265223 |    185.495940 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                     |
| 600 |     28.675495 |    752.195464 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 601 |    369.188542 |    447.989847 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 602 |    873.605161 |    119.690194 | (unknown)                                                                                                                                                                            |
| 603 |    521.796382 |    190.010841 | Chris huh                                                                                                                                                                            |
| 604 |    662.380836 |    698.788481 | Fernando Campos De Domenico                                                                                                                                                          |
| 605 |    604.638079 |    202.996874 | L. Shyamal                                                                                                                                                                           |
| 606 |    156.340707 |     33.933582 | NA                                                                                                                                                                                   |
| 607 |    855.679803 |    675.447795 | Ferran Sayol                                                                                                                                                                         |
| 608 |    996.355061 |    372.970391 | Marmelad                                                                                                                                                                             |
| 609 |    605.343921 |    763.921303 | Zimices                                                                                                                                                                              |
| 610 |    240.244744 |    402.861150 | Robert Gay, modifed from Olegivvit                                                                                                                                                   |
| 611 |    782.021524 |    408.104830 | Jaime Headden                                                                                                                                                                        |
| 612 |    820.409310 |    435.199757 | Matt Crook                                                                                                                                                                           |
| 613 |    989.090687 |    765.136841 | Margot Michaud                                                                                                                                                                       |
| 614 |    651.525468 |    534.975017 | Anna Willoughby                                                                                                                                                                      |
| 615 |     73.794179 |    695.445157 | NA                                                                                                                                                                                   |
| 616 |     18.149597 |    500.246929 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                                 |
| 617 |    283.356340 |    401.330479 | Jiekun He                                                                                                                                                                            |
| 618 |    733.711295 |    452.396493 | Lukasiniho                                                                                                                                                                           |
| 619 |    278.353278 |    753.853596 | Andy Wilson                                                                                                                                                                          |
| 620 |     32.523172 |    300.792912 | Felix Vaux                                                                                                                                                                           |
| 621 |    768.178204 |    164.514531 | Matt Crook                                                                                                                                                                           |
| 622 |    322.393534 |    396.824639 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
| 623 |    741.013028 |    490.334971 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                                          |
| 624 |   1015.410377 |    584.770837 | Gareth Monger                                                                                                                                                                        |
| 625 |    863.538445 |    419.038607 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 626 |   1013.472390 |    609.802053 | Matt Crook                                                                                                                                                                           |
| 627 |    557.150005 |    180.599449 | Tasman Dixon                                                                                                                                                                         |
| 628 |    554.534715 |    775.734730 | T. Michael Keesey                                                                                                                                                                    |
| 629 |    317.280507 |     50.008821 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 630 |    614.455779 |    323.423210 | Beth Reinke                                                                                                                                                                          |
| 631 |     59.409314 |    430.125450 | Scott Hartman                                                                                                                                                                        |
| 632 |    963.402950 |     82.226074 | Zimices                                                                                                                                                                              |
| 633 |    367.997312 |    784.005347 | T. Michael Keesey                                                                                                                                                                    |
| 634 |    892.947134 |    150.646927 | Andy Wilson                                                                                                                                                                          |
| 635 |    658.135707 |     13.210892 | Birgit Lang                                                                                                                                                                          |
| 636 |    672.542432 |    706.311837 | Mark Witton                                                                                                                                                                          |
| 637 |    170.501716 |    418.843354 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 638 |    909.842586 |    524.173922 | T. Michael Keesey                                                                                                                                                                    |
| 639 |    918.537658 |    380.884194 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                               |
| 640 |   1003.386880 |    696.990225 | Matt Crook                                                                                                                                                                           |
| 641 |    818.272672 |     68.823581 | Lukasiniho                                                                                                                                                                           |
| 642 |    126.589090 |    134.821694 | Birgit Lang                                                                                                                                                                          |
| 643 |    789.487121 |    346.050868 | Chris huh                                                                                                                                                                            |
| 644 |    376.311299 |    355.906433 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                                         |
| 645 |    988.685610 |    649.451073 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
| 646 |     88.563572 |    376.473938 | Anthony Caravaggi                                                                                                                                                                    |
| 647 |    523.495984 |      8.811743 | Sarah Werning                                                                                                                                                                        |
| 648 |    522.154001 |    278.632202 | Birgit Lang                                                                                                                                                                          |
| 649 |    283.065886 |    299.893997 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 650 |    720.115951 |     42.523928 | Anthony Caravaggi                                                                                                                                                                    |
| 651 |    943.414539 |    437.798292 | Chris A. Hamilton                                                                                                                                                                    |
| 652 |    126.228954 |     58.503875 | Andy Wilson                                                                                                                                                                          |
| 653 |    256.034387 |    279.546348 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 654 |   1008.841267 |    708.162142 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 655 |    422.126379 |    504.120898 | Markus A. Grohme                                                                                                                                                                     |
| 656 |    644.527123 |    727.483748 | Matt Crook                                                                                                                                                                           |
| 657 |    478.785545 |    632.755841 | NA                                                                                                                                                                                   |
| 658 |    123.636202 |    359.277974 | Ferran Sayol                                                                                                                                                                         |
| 659 |    990.525471 |    384.863525 | Matt Crook                                                                                                                                                                           |
| 660 |    839.359721 |     25.565110 | NA                                                                                                                                                                                   |
| 661 |    181.003805 |    664.592077 | Matt Dempsey                                                                                                                                                                         |
| 662 |    348.361330 |    272.311661 | Matt Crook                                                                                                                                                                           |
| 663 |    344.625836 |    357.140484 | Beth Reinke                                                                                                                                                                          |
| 664 |    575.885286 |    104.003131 | Ieuan Jones                                                                                                                                                                          |
| 665 |    841.021493 |    318.700590 | Margot Michaud                                                                                                                                                                       |
| 666 |   1005.960814 |    490.862694 | T. Michael Keesey                                                                                                                                                                    |
| 667 |    591.169318 |     85.188329 | Ewald Rübsamen                                                                                                                                                                       |
| 668 |    630.994727 |    422.366509 | NA                                                                                                                                                                                   |
| 669 |   1009.753526 |    336.295446 | Gareth Monger                                                                                                                                                                        |
| 670 |    834.318133 |    508.763986 | Ferran Sayol                                                                                                                                                                         |
| 671 |    445.188082 |    346.040298 | Michael Scroggie                                                                                                                                                                     |
| 672 |    614.520926 |    246.028821 | Noah Schlottman                                                                                                                                                                      |
| 673 |    894.052222 |    504.704196 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                                       |
| 674 |     17.390807 |    771.555389 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 675 |    731.561631 |    761.104064 | Jack Mayer Wood                                                                                                                                                                      |
| 676 |     27.053261 |    432.310508 | xgirouxb                                                                                                                                                                             |
| 677 |    266.624090 |    505.092422 | Caleb M. Brown                                                                                                                                                                       |
| 678 |    326.556171 |     17.000475 | Jagged Fang Designs                                                                                                                                                                  |
| 679 |    816.556098 |    146.265541 | Heinrich Harder (vectorized by William Gearty)                                                                                                                                       |
| 680 |    432.901526 |    158.658849 | Christoph Schomburg                                                                                                                                                                  |
| 681 |    180.054096 |     57.767530 | Chris huh                                                                                                                                                                            |
| 682 |    546.999161 |    545.925266 | Ferran Sayol                                                                                                                                                                         |
| 683 |    989.583965 |    398.660946 | Steven Traver                                                                                                                                                                        |
| 684 |    510.388158 |    638.644789 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 685 |    951.705028 |    669.332455 | Steven Traver                                                                                                                                                                        |
| 686 |   1011.989227 |    376.185748 | Gareth Monger                                                                                                                                                                        |
| 687 |    914.184274 |     16.463273 | Margot Michaud                                                                                                                                                                       |
| 688 |    740.371012 |     69.789287 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 689 |    166.214970 |    564.257774 | Steven Traver                                                                                                                                                                        |
| 690 |   1014.471747 |     10.794666 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 691 |    512.083771 |     39.537938 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 692 |     58.568361 |    613.382230 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 693 |    132.512347 |    728.502373 | Matt Crook                                                                                                                                                                           |
| 694 |    154.203079 |    307.295487 | NA                                                                                                                                                                                   |
| 695 |    436.032239 |     57.051280 | Dean Schnabel                                                                                                                                                                        |
| 696 |    144.375996 |    450.618972 | Andy Wilson                                                                                                                                                                          |
| 697 |    154.662129 |    684.464667 | L. Shyamal                                                                                                                                                                           |
| 698 |    926.216551 |    337.998731 | Steven Traver                                                                                                                                                                        |
| 699 |    203.226148 |    107.330260 | Thibaut Brunet                                                                                                                                                                       |
| 700 |    852.098168 |    116.437042 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 701 |    346.526807 |    109.356812 | Jack Mayer Wood                                                                                                                                                                      |
| 702 |    848.501402 |    374.329623 | Scott Hartman                                                                                                                                                                        |
| 703 |    537.213306 |    456.447230 | Chris Hay                                                                                                                                                                            |
| 704 |    439.084714 |    301.829173 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 705 |     82.408429 |     27.979174 | Ferran Sayol                                                                                                                                                                         |
| 706 |    113.550857 |    614.510108 | Birgit Lang; original image by virmisco.org                                                                                                                                          |
| 707 |    785.723034 |    450.528478 | Yan Wong                                                                                                                                                                             |
| 708 |    421.491346 |    121.356126 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 709 |    863.801965 |    733.204412 | Matt Crook                                                                                                                                                                           |
| 710 |    926.949081 |    142.019681 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 711 |    560.857240 |    282.254062 | Margot Michaud                                                                                                                                                                       |
| 712 |    179.134543 |    712.165325 | Ferran Sayol                                                                                                                                                                         |
| 713 |     34.679513 |    676.370700 | Ferran Sayol                                                                                                                                                                         |
| 714 |    746.077074 |    466.073800 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 715 |    957.213119 |    418.230286 | Matt Celeskey                                                                                                                                                                        |
| 716 |    599.646803 |    436.118217 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                                    |
| 717 |    308.165414 |    443.353041 | Scott Hartman                                                                                                                                                                        |
| 718 |    913.588112 |    297.378770 | Matt Crook                                                                                                                                                                           |
| 719 |    134.112412 |     29.893157 | Anthony Caravaggi                                                                                                                                                                    |
| 720 |    309.859099 |    706.167042 | Christoph Schomburg                                                                                                                                                                  |
| 721 |    587.953555 |    612.603424 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 722 |     57.544182 |    214.874511 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                                |
| 723 |    738.472622 |    506.736814 | T. Michael Keesey                                                                                                                                                                    |
| 724 |    613.535387 |    421.993917 | Rebecca Groom                                                                                                                                                                        |
| 725 |    831.109562 |    772.177690 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 726 |    756.547890 |    645.846094 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 727 |   1003.172434 |    277.148770 | T. Michael Keesey                                                                                                                                                                    |
| 728 |    922.866098 |    405.096035 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 729 |    788.760985 |    473.959831 | Andy Wilson                                                                                                                                                                          |
| 730 |    201.207634 |    123.909759 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                         |
| 731 |    395.228547 |    464.256924 | Markus A. Grohme                                                                                                                                                                     |
| 732 |    547.004390 |    765.176300 | Matt Crook                                                                                                                                                                           |
| 733 |    479.059104 |    499.636069 | Scott Hartman                                                                                                                                                                        |
| 734 |    287.763355 |    421.315846 | Matt Crook                                                                                                                                                                           |
| 735 |    956.034077 |    684.440244 | Sarah Werning                                                                                                                                                                        |
| 736 |    495.688288 |    559.368063 | Darius Nau                                                                                                                                                                           |
| 737 |    868.421965 |    379.637807 | Maija Karala                                                                                                                                                                         |
| 738 |    377.618063 |    768.216903 | Darius Nau                                                                                                                                                                           |
| 739 |    701.030098 |     38.302005 | Matt Wilkins                                                                                                                                                                         |
| 740 |    329.414027 |    240.728400 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 741 |    987.604527 |    684.622590 | Scott Hartman                                                                                                                                                                        |
| 742 |    361.607038 |    258.661158 | Anthony Caravaggi                                                                                                                                                                    |
| 743 |    696.224479 |    138.604385 | Emily Willoughby                                                                                                                                                                     |
| 744 |    391.119396 |    305.196765 | Chris huh                                                                                                                                                                            |
| 745 |    959.420764 |    568.039562 | Margot Michaud                                                                                                                                                                       |
| 746 |    502.946467 |    195.080126 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 747 |     88.026182 |     87.509047 | Margot Michaud                                                                                                                                                                       |
| 748 |    575.775435 |    366.749162 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 749 |    327.097323 |    277.088114 | Scott Hartman                                                                                                                                                                        |
| 750 |    867.682966 |    113.258817 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 751 |    908.249935 |    141.614602 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 752 |    221.111048 |     78.667998 | Tasman Dixon                                                                                                                                                                         |
| 753 |    134.150685 |    467.925680 | Harold N Eyster                                                                                                                                                                      |
| 754 |    541.086580 |    272.869139 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                                 |
| 755 |    588.208864 |    751.311475 | Gareth Monger                                                                                                                                                                        |
| 756 |     32.905267 |    373.338116 | Mario Quevedo                                                                                                                                                                        |
| 757 |    364.280883 |    142.315649 | Margot Michaud                                                                                                                                                                       |
| 758 |    651.358215 |    207.000454 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                                            |
| 759 |    329.757750 |    457.367325 | Mariana Ruiz Villarreal                                                                                                                                                              |
| 760 |    739.109647 |    475.579320 | Chris Jennings (Risiatto)                                                                                                                                                            |
| 761 |    931.230099 |    527.382727 | Christina N. Hodson                                                                                                                                                                  |
| 762 |    950.643846 |    765.763427 | Maija Karala                                                                                                                                                                         |
| 763 |    554.764377 |     52.446424 | Ben Liebeskind                                                                                                                                                                       |
| 764 |    784.334695 |     93.898238 | Zimices                                                                                                                                                                              |
| 765 |    707.866619 |     10.114138 | Geoff Shaw                                                                                                                                                                           |
| 766 |    598.628457 |    791.644182 | Tracy A. Heath                                                                                                                                                                       |
| 767 |    515.719733 |    462.182117 | Joanna Wolfe                                                                                                                                                                         |
| 768 |    912.547442 |    736.386785 | Maxime Dahirel                                                                                                                                                                       |
| 769 |    210.413610 |    774.578309 | Beth Reinke                                                                                                                                                                          |
| 770 |    662.956458 |    591.095997 | Jagged Fang Designs                                                                                                                                                                  |
| 771 |    557.464172 |    352.766252 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 772 |    661.946802 |    424.399856 | T. Michael Keesey                                                                                                                                                                    |
| 773 |    849.953498 |    213.377353 | Matt Crook                                                                                                                                                                           |
| 774 |    814.780451 |     34.450914 | Sarah Werning                                                                                                                                                                        |
| 775 |    456.125670 |    337.889893 | Emily Willoughby                                                                                                                                                                     |
| 776 |    308.058240 |    510.384664 | Jack Mayer Wood                                                                                                                                                                      |
| 777 |    709.389360 |    579.703668 | Christoph Schomburg                                                                                                                                                                  |
| 778 |    929.506076 |    631.381706 | Markus A. Grohme                                                                                                                                                                     |
| 779 |    309.870732 |    396.368650 | Michelle Site                                                                                                                                                                        |
| 780 |    985.040468 |    699.623308 | Chuanixn Yu                                                                                                                                                                          |
| 781 |    526.516773 |    268.798524 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 782 |    773.256178 |     33.581966 | Dmitry Bogdanov                                                                                                                                                                      |
| 783 |    479.360712 |    790.753558 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                                   |
| 784 |    662.447043 |    195.374504 | Anthony Caravaggi                                                                                                                                                                    |
| 785 |    931.685344 |    346.723788 | Zachary Quigley                                                                                                                                                                      |
| 786 |    996.667973 |    343.269799 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                         |
| 787 |     56.890117 |     90.260541 | Jagged Fang Designs                                                                                                                                                                  |
| 788 |    474.375443 |     90.360306 | Felix Vaux                                                                                                                                                                           |
| 789 |    184.816919 |    286.611830 | Martin R. Smith                                                                                                                                                                      |
| 790 |     50.919356 |    276.741214 | Zimices                                                                                                                                                                              |
| 791 |    404.716282 |    123.183931 | Gareth Monger                                                                                                                                                                        |
| 792 |    627.791353 |    702.603436 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 793 |    839.256362 |    757.957003 | Michael P. Taylor                                                                                                                                                                    |
| 794 |    695.177789 |     28.964921 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 795 |    963.200307 |     30.676016 | Matt Crook                                                                                                                                                                           |
| 796 |    131.938932 |    666.271606 | Matt Crook                                                                                                                                                                           |
| 797 |    929.128187 |    327.999367 | Zimices                                                                                                                                                                              |
| 798 |    191.933230 |    674.765963 | Gareth Monger                                                                                                                                                                        |
| 799 |    151.092659 |    441.666143 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 800 |    997.378771 |    302.810062 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 801 |    554.212628 |    457.433946 | Andy Wilson                                                                                                                                                                          |
| 802 |      8.577439 |     56.119595 | Ferran Sayol                                                                                                                                                                         |
| 803 |    520.079230 |    679.714735 | Ferran Sayol                                                                                                                                                                         |
| 804 |    125.656250 |     93.894413 | Margot Michaud                                                                                                                                                                       |
| 805 |    857.615081 |    509.900923 | Zimices                                                                                                                                                                              |
| 806 |    721.061784 |    513.709718 | Pete Buchholz                                                                                                                                                                        |
| 807 |    500.695997 |    294.764331 | T. Michael Keesey (after Monika Betley)                                                                                                                                              |
| 808 |    883.823594 |    739.863600 | T. Michael Keesey                                                                                                                                                                    |
| 809 |    403.007303 |    697.049980 | Dean Schnabel                                                                                                                                                                        |
| 810 |    787.562146 |    611.101936 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 811 |    337.264820 |    325.985699 | Chloé Schmidt                                                                                                                                                                        |
| 812 |    750.523713 |    623.238393 | Renato Santos                                                                                                                                                                        |
| 813 |    136.180329 |    293.464642 | Andy Wilson                                                                                                                                                                          |
| 814 |    997.966588 |    289.261853 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 815 |    971.354825 |    128.318799 | Jaime Headden                                                                                                                                                                        |
| 816 |     58.698132 |    236.129523 | Alexandre Vong                                                                                                                                                                       |
| 817 |     63.655693 |    373.174692 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 818 |    162.958479 |    483.460291 | Taro Maeda                                                                                                                                                                           |
| 819 |    716.648925 |    119.436834 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 820 |     18.144051 |    516.263313 | Scott Hartman                                                                                                                                                                        |
| 821 |    934.329286 |    295.985422 | Jagged Fang Designs                                                                                                                                                                  |
| 822 |    897.460726 |    114.408045 | Gareth Monger                                                                                                                                                                        |
| 823 |    152.360325 |    468.066004 | Dmitry Bogdanov                                                                                                                                                                      |
| 824 |    207.997624 |     68.142429 | Anthony Caravaggi                                                                                                                                                                    |
| 825 |    405.877528 |    433.798734 | Kai R. Caspar                                                                                                                                                                        |
| 826 |    624.916462 |    574.810696 | Matt Crook                                                                                                                                                                           |
| 827 |    116.040054 |    734.871868 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 828 |    505.911710 |    755.922154 | Gareth Monger                                                                                                                                                                        |
| 829 |   1011.627018 |     92.310665 | Andy Wilson                                                                                                                                                                          |
| 830 |    115.149560 |     11.965151 | Maija Karala                                                                                                                                                                         |
| 831 |     69.225979 |    545.489258 | Emily Willoughby                                                                                                                                                                     |
| 832 |    222.606458 |    404.357530 | Alex Slavenko                                                                                                                                                                        |
| 833 |    971.238972 |    376.201882 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 834 |    633.557298 |    708.190173 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 835 |    381.381010 |    660.032487 | Caleb M. Brown                                                                                                                                                                       |
| 836 |    670.851462 |    531.153613 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 837 |    405.281679 |    450.602779 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                                        |
| 838 |    267.377597 |    395.200536 | Scott Hartman                                                                                                                                                                        |
| 839 |    141.290150 |    694.315941 | Gareth Monger                                                                                                                                                                        |
| 840 |    546.145732 |    185.308782 | Margot Michaud                                                                                                                                                                       |
| 841 |    681.152688 |    657.339622 | Chuanixn Yu                                                                                                                                                                          |
| 842 |    513.395529 |     62.210325 | Katie S. Collins                                                                                                                                                                     |
| 843 |    915.638061 |    612.792019 | Becky Barnes                                                                                                                                                                         |
| 844 |    527.733264 |    779.953422 | T. Michael Keesey                                                                                                                                                                    |
| 845 |    211.333628 |    118.389378 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 846 |    666.008323 |    215.182267 | Matt Wilkins                                                                                                                                                                         |
| 847 |    900.965260 |     57.784757 | Andy Wilson                                                                                                                                                                          |
| 848 |    594.749399 |    480.524525 | Margot Michaud                                                                                                                                                                       |
| 849 |    946.348663 |    424.566384 | T. Michael Keesey                                                                                                                                                                    |
| 850 |    682.259376 |    754.340651 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 851 |    503.467137 |    768.559773 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 852 |    577.706920 |    245.572729 | Kamil S. Jaron                                                                                                                                                                       |
| 853 |    535.956031 |    544.344220 | Steven Traver                                                                                                                                                                        |
| 854 |    517.328484 |     21.059067 | Chris huh                                                                                                                                                                            |
| 855 |    552.597536 |    794.257301 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 856 |    962.773298 |    433.674911 | Hugo Gruson                                                                                                                                                                          |
| 857 |    368.132074 |    207.391549 | T. Michael Keesey                                                                                                                                                                    |
| 858 |    169.569655 |    632.905760 | nicubunu                                                                                                                                                                             |
| 859 |    589.436021 |    514.483207 | Emily Jane McTavish                                                                                                                                                                  |
| 860 |    375.795075 |    688.473631 | Zimices                                                                                                                                                                              |
| 861 |    300.700631 |    275.391873 | Steven Traver                                                                                                                                                                        |
| 862 |    712.867428 |    755.556990 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 863 |    194.105077 |     51.935583 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 864 |    828.509042 |      1.760867 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 865 |    816.163727 |      8.598907 | Steven Traver                                                                                                                                                                        |
| 866 |    658.310503 |    134.965284 | Steven Traver                                                                                                                                                                        |
| 867 |    836.453153 |    197.373077 | Rebecca Groom                                                                                                                                                                        |
| 868 |    521.493218 |    580.744582 | Zimices                                                                                                                                                                              |
| 869 |    742.664562 |    576.177169 | Riccardo Percudani                                                                                                                                                                   |
| 870 |    331.666379 |    319.418721 | Zimices                                                                                                                                                                              |
| 871 |    183.052364 |    236.682867 | FunkMonk                                                                                                                                                                             |
| 872 |    811.299217 |    470.434571 | Cesar Julian                                                                                                                                                                         |
| 873 |    806.749344 |     98.032962 | Yan Wong                                                                                                                                                                             |
| 874 |    225.840623 |    496.866693 | Steven Traver                                                                                                                                                                        |
| 875 |    799.099171 |    427.897429 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 876 |    861.591913 |     52.251751 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                               |
| 877 |    246.746335 |    151.084483 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 878 |    761.905568 |    333.899078 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 879 |    741.708266 |    768.028588 | Matt Crook                                                                                                                                                                           |
| 880 |    844.439815 |    493.059929 | Mike Hanson                                                                                                                                                                          |
| 881 |    154.815654 |    137.512540 | Oren Peles / vectorized by Yan Wong                                                                                                                                                  |
| 882 |    110.440954 |    138.702892 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 883 |    322.507490 |    694.940182 | Margot Michaud                                                                                                                                                                       |
| 884 |    727.222266 |      4.950909 | Kai R. Caspar                                                                                                                                                                        |
| 885 |    329.834962 |    339.754658 | Mathilde Cordellier                                                                                                                                                                  |
| 886 |    165.432460 |    642.038799 | Tony Ayling                                                                                                                                                                          |
| 887 |    499.113070 |     20.834437 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 888 |    407.277971 |    649.437251 | Ferran Sayol                                                                                                                                                                         |
| 889 |    406.802904 |    661.981686 | Ferran Sayol                                                                                                                                                                         |
| 890 |    965.824533 |     59.090260 | Birgit Lang                                                                                                                                                                          |
| 891 |    586.620064 |    295.769740 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                     |
| 892 |    471.237891 |    275.006032 | Ignacio Contreras                                                                                                                                                                    |
| 893 |    185.767269 |    423.120360 | Joanna Wolfe                                                                                                                                                                         |
| 894 |     19.700662 |     85.464265 | T. Michael Keesey                                                                                                                                                                    |
| 895 |    559.200041 |    172.373792 | Jaime Headden                                                                                                                                                                        |
| 896 |    191.933333 |    253.528847 | Xavier Giroux-Bougard                                                                                                                                                                |
| 897 |    462.390350 |    711.143834 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 898 |    917.809612 |    448.274539 | Chloé Schmidt                                                                                                                                                                        |
| 899 |    984.276003 |    544.857558 | NA                                                                                                                                                                                   |
| 900 |     40.073515 |     65.656670 | Zimices                                                                                                                                                                              |
| 901 |    855.417247 |    168.546544 | Beth Reinke                                                                                                                                                                          |
| 902 |    792.373647 |    432.073371 | Scott Hartman                                                                                                                                                                        |
| 903 |    827.102441 |    353.685366 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 904 |    514.170036 |    408.119864 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                        |
| 905 |    531.809638 |    665.615220 | Harold N Eyster                                                                                                                                                                      |
| 906 |     16.328998 |    753.740713 | Felix Vaux                                                                                                                                                                           |
| 907 |    540.325608 |    291.268410 | Andrew Farke and Joseph Sertich                                                                                                                                                      |
| 908 |    718.515311 |    768.821180 | Matt Crook                                                                                                                                                                           |
| 909 |    943.828589 |     94.013950 | Dean Schnabel                                                                                                                                                                        |
| 910 |    375.221469 |     72.844379 | Jagged Fang Designs                                                                                                                                                                  |
| 911 |    470.721543 |     63.569681 | Margot Michaud                                                                                                                                                                       |
| 912 |    166.469361 |    300.463030 | Zimices                                                                                                                                                                              |
| 913 |    266.935010 |    671.665943 | Markus A. Grohme                                                                                                                                                                     |

    #> Your tweet has been posted!
