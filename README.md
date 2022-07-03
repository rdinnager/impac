
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

Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Anthony Caravaggi, Pedro de Siracusa, Tim H. Heupink,
Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey),
Ghedoghedo (vectorized by T. Michael Keesey), Christoph Schomburg,
Jagged Fang Designs, Matt Crook, Margot Michaud, Francisco Gascó
(modified by Michael P. Taylor), Armin Reindl, T. Michael Keesey, Luc
Viatour (source photo) and Andreas Plank, Gabriela Palomo-Munoz, Markus
A. Grohme, Andy Wilson, Scott Hartman, Steven Traver, Jaime Headden,
CNZdenek, Apokryltaros (vectorized by T. Michael Keesey), Tasman Dixon,
Chloé Schmidt, Ignacio Contreras, Zimices, Lip Kee Yap (vectorized by T.
Michael Keesey), Servien (vectorized by T. Michael Keesey), FunkMonk,
Pete Buchholz, Isaure Scavezzoni, C. Camilo Julián-Caballero, Beth
Reinke, Chris huh, Rebecca Groom, Nobu Tamura (vectorized by T. Michael
Keesey), Nina Skinner, Kent Elson Sorgon, Nobu Tamura, vectorized by
Zimices, Tony Ayling (vectorized by T. Michael Keesey), T. Michael
Keesey (vectorization) and HuttyMcphoo (photography), Ingo Braasch,
Zsoldos Márton (vectorized by T. Michael Keesey), Roberto Díaz Sibaja,
E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey), Lee Harding
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Dmitry Bogdanov (vectorized by T. Michael Keesey), Emily Jane
McTavish, Elisabeth Östman, Jessica Anne Miller, Dean Schnabel, Ferran
Sayol, Gareth Monger, Chuanixn Yu, Katie S. Collins, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Conty (vectorized by T. Michael Keesey), Jack Mayer
Wood, Alex Slavenko, Carlos Cano-Barbacil, Erika Schumacher, Smokeybjb,
Tyler McCraney, Falconaumanni and T. Michael Keesey, Sarah Werning,
Verisimilus, Michelle Site, Tarique Sani (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Matt Dempsey, Jon Hill,
Javier Luque, Joanna Wolfe, Ville Koistinen and T. Michael Keesey, Caleb
M. Brown, Fernando Carezzano, H. F. O. March (modified by T. Michael
Keesey, Michael P. Taylor & Matthew J. Wedel), Jose Carlos
Arenas-Monroy, Fernando Campos De Domenico, Felix Vaux, Rachel Shoop,
Renato de Carvalho Ferreira, Emily Willoughby, Collin Gross, Kailah
Thorn & Ben King, Birgit Lang, Yan Wong from drawing by T. F.
Zimmermann, T. Michael Keesey (after Marek Velechovský), Christina N.
Hodson, Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on
iNaturalist, Evan-Amos (vectorized by T. Michael Keesey), Sharon
Wegner-Larsen, JCGiron, Jake Warner, Original photo by Andrew Murray,
vectorized by Roberto Díaz Sibaja, M Kolmann, Nicholas J. Czaplewski,
vectorized by Zimices, Jiekun He, Noah Schlottman, photo by Gustav
Paulay for Moorea Biocode, Mattia Menchetti, Stanton F. Fink (vectorized
by T. Michael Keesey), Tracy A. Heath, Hugo Gruson, Lindberg (vectorized
by T. Michael Keesey), Mette Aumala, Douglas Brown (modified by T.
Michael Keesey), Marmelad, TaraTaylorDesign, Amanda Katzer, Matt Wilkins
(photo by Patrick Kavanagh), Cristina Guijarro, Andrew A. Farke, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Theodore W. Pietsch (photography) and T. Michael
Keesey (vectorization), Matt Martyniuk, Yan Wong, Alexander
Schmidt-Lebuhn, Haplochromis (vectorized by T. Michael Keesey), Richard
J. Harris, L. Shyamal, Noah Schlottman, photo by Casey Dunn, David Sim
(photograph) and T. Michael Keesey (vectorization), Todd Marshall,
vectorized by Zimices, B. Duygu Özpolat, Maxime Dahirel (digitisation),
Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original
publication), Taro Maeda, Milton Tan, Mathilde Cordellier, Steven
Coombs, Andreas Trepte (vectorized by T. Michael Keesey), Kanchi Nanjo,
Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary,
Ieuan Jones, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), John
Conway, James R. Spotila and Ray Chatterji, Josefine Bohr Brask, David
Orr, T. Michael Keesey (vectorization) and Nadiatalent (photography),
Noah Schlottman, photo by Carol Cummings, Cesar Julian, Felix Vaux and
Steven A. Trewick, NOAA (vectorized by T. Michael Keesey), \[unknown\],
DW Bapst (modified from Bulman, 1970), Berivan Temiz, Pollyanna von
Knorring and T. Michael Keesey, Fir0002/Flagstaffotos (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Maha Ghazal,
NASA, Abraão Leite, Elizabeth Parker, Kimberly Haddrell, Michael
Scroggie, Ludwik Gąsiorowski, Verdilak, Kamil S. Jaron, T. Michael
Keesey (after Monika Betley), Jonathan Wells, Danielle Alba, T. Michael
Keesey (vectorization); Yves Bousquet (photography), Unknown (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
mystica, Kristina Gagalova, Leann Biancani, photo by Kenneth Clifton,
Acrocynus (vectorized by T. Michael Keesey), Matt Celeskey, Birgit Lang,
based on a photo by D. Sikes, Iain Reid, T. Michael Keesey, from a
photograph by Thea Boodhoo, Brad McFeeters (vectorized by T. Michael
Keesey), Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz
Sibaja, Darren Naish (vectorized by T. Michael Keesey), Pranav Iyer
(grey ideas), DW Bapst, modified from Ishitani et al. 2016, Remes K,
Ortega F, Fierro I, Joger U, Kosma R, et al., Kai R. Caspar, Mali’o
Kodis, image from the Biodiversity Heritage Library, Mathew Wedel,
xgirouxb, Shyamal, Skye McDavid, Lily Hughes, James I. Kirkland, Luis
Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), Martin R. Smith, Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., Ben Liebeskind, Lisa M. “Pixxl” (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Notafly (vectorized by T. Michael Keesey), Patrick Fisher (vectorized by
T. Michael Keesey), Jaime A. Headden (vectorized by T. Michael Keesey),
Natalie Claunch, Aadx, Maija Karala, Richard Lampitt, Jeremy Young / NHM
(vectorization by Yan Wong), Mark Witton, Harold N Eyster, Tauana J.
Cunha, Jakovche, Nobu Tamura, Christine Axon, Matt Hayes, Mali’o Kodis,
photograph by John Slapcinsky, Darius Nau, Melissa Broussard, , Robert
Bruce Horsfall (vectorized by T. Michael Keesey), Christopher Watson
(photo) and T. Michael Keesey (vectorization), Alexandre Vong, Mathieu
Basille, S.Martini, Mathieu Pélissié, Neil Kelley, A. H. Baldwin
(vectorized by T. Michael Keesey), Audrey Ely, Noah Schlottman, Charles
Doolittle Walcott (vectorized by T. Michael Keesey), Benjamint444, Chase
Brownstein, V. Deepak, Tony Ayling, T. Michael Keesey (photo by Sean
Mack), JJ Harrison (vectorized by T. Michael Keesey), Lukasiniho, (after
McCulloch 1908), Mykle Hoban, Agnello Picorelli, Raven Amos, Peileppe,
Samanta Orellana, Scott Reid, Wayne Decatur, Frank Denota, Oscar
Sanisidro, Dmitry Bogdanov, Birgit Lang; original image by virmisco.org,
Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong), Mali’o Kodis,
photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>),
Pearson Scott Foresman (vectorized by T. Michael Keesey), Xavier
Giroux-Bougard, Tambja (vectorized by T. Michael Keesey), Terpsichores,
Oren Peles / vectorized by Yan Wong, Aviceda (photo) & T. Michael
Keesey, Manabu Sakamoto, wsnaccad, Smokeybjb, vectorized by Zimices,
Ricardo Araújo, Emma Kissling, L.M. Davalos, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Mattia Menchetti / Yan Wong, Didier Descouens (vectorized
by T. Michael Keesey), Robbie N. Cada (vectorized by T. Michael Keesey),
Noah Schlottman, photo by David J Patterson, Jaime Headden, modified by
T. Michael Keesey, Moussa Direct Ltd. (photography) and T. Michael
Keesey (vectorization), Matt Martyniuk (vectorized by T. Michael
Keesey), Dmitry Bogdanov (modified by T. Michael Keesey), Gopal Murali,
LeonardoG (photography) and T. Michael Keesey (vectorization), Birgit
Lang; based on a drawing by C.L. Koch, Noah Schlottman, photo by Antonio
Guillén, Christian A. Masnaghetti, Martin Kevil, H. Filhol (vectorized
by T. Michael Keesey), Cathy, Obsidian Soul (vectorized by T. Michael
Keesey), Mason McNair, Zachary Quigley, Sergio A. Muñoz-Gómez

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    948.885291 |    634.345410 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
|   2 |     87.455290 |    509.928071 | Anthony Caravaggi                                                                                                                                                     |
|   3 |    238.647250 |    213.518802 | Pedro de Siracusa                                                                                                                                                     |
|   4 |    313.685510 |    609.424017 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
|   5 |     92.470670 |    602.444583 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|   6 |    974.358237 |    478.382250 | Christoph Schomburg                                                                                                                                                   |
|   7 |    213.882647 |    400.055289 | Jagged Fang Designs                                                                                                                                                   |
|   8 |    432.689737 |    229.667607 | Matt Crook                                                                                                                                                            |
|   9 |    823.485245 |    215.438335 | Margot Michaud                                                                                                                                                        |
|  10 |    538.860177 |    147.889148 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
|  11 |    855.074265 |    581.994562 | Armin Reindl                                                                                                                                                          |
|  12 |     63.554112 |    739.992869 | Margot Michaud                                                                                                                                                        |
|  13 |    608.510833 |    398.231908 | T. Michael Keesey                                                                                                                                                     |
|  14 |    293.366691 |    312.924025 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
|  15 |    567.786042 |     74.706603 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  16 |    364.772597 |     39.530698 | Markus A. Grohme                                                                                                                                                      |
|  17 |    680.129437 |    631.488320 | Andy Wilson                                                                                                                                                           |
|  18 |    472.294314 |    401.598572 | T. Michael Keesey                                                                                                                                                     |
|  19 |    471.622787 |    608.587297 | Scott Hartman                                                                                                                                                         |
|  20 |    522.439614 |    698.449889 | Steven Traver                                                                                                                                                         |
|  21 |    905.537802 |    769.474300 | Scott Hartman                                                                                                                                                         |
|  22 |    616.864998 |     44.076407 | Steven Traver                                                                                                                                                         |
|  23 |    947.746219 |     32.603578 | Jaime Headden                                                                                                                                                         |
|  24 |    753.823064 |    742.380035 | CNZdenek                                                                                                                                                              |
|  25 |    395.240830 |    119.913845 | Steven Traver                                                                                                                                                         |
|  26 |    697.095357 |    467.278729 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
|  27 |    654.442996 |    206.887745 | Tasman Dixon                                                                                                                                                          |
|  28 |    568.866501 |    309.045176 | Chloé Schmidt                                                                                                                                                         |
|  29 |    220.323559 |    503.615466 | Jagged Fang Designs                                                                                                                                                   |
|  30 |    837.149886 |    433.626420 | Scott Hartman                                                                                                                                                         |
|  31 |    315.336793 |    748.571657 | Ignacio Contreras                                                                                                                                                     |
|  32 |    729.097389 |    276.388308 | Margot Michaud                                                                                                                                                        |
|  33 |    540.028703 |    478.130927 | Jaime Headden                                                                                                                                                         |
|  34 |    898.947393 |    292.090228 | Zimices                                                                                                                                                               |
|  35 |    224.198471 |     89.101374 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
|  36 |    781.089108 |    116.118945 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
|  37 |    324.799552 |    504.215470 | T. Michael Keesey                                                                                                                                                     |
|  38 |    664.035308 |    552.282020 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  39 |    283.061973 |    425.538236 | FunkMonk                                                                                                                                                              |
|  40 |    830.442230 |    397.844412 | Pete Buchholz                                                                                                                                                         |
|  41 |    736.459970 |    352.817027 | Isaure Scavezzoni                                                                                                                                                     |
|  42 |    667.743347 |    693.326772 | C. Camilo Julián-Caballero                                                                                                                                            |
|  43 |    121.038548 |    156.184332 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  44 |    960.741663 |    140.371048 | Beth Reinke                                                                                                                                                           |
|  45 |    588.258998 |    767.556156 | Chris huh                                                                                                                                                             |
|  46 |    944.684227 |    349.320036 | Anthony Caravaggi                                                                                                                                                     |
|  47 |    234.217285 |    643.351827 | Jagged Fang Designs                                                                                                                                                   |
|  48 |    475.650356 |    576.307630 | Markus A. Grohme                                                                                                                                                      |
|  49 |     77.565539 |    663.611977 | Rebecca Groom                                                                                                                                                         |
|  50 |    371.255264 |    756.430201 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  51 |    578.056792 |    589.012461 | Nina Skinner                                                                                                                                                          |
|  52 |    862.805088 |    339.611338 | Scott Hartman                                                                                                                                                         |
|  53 |    203.893260 |    726.676867 | Matt Crook                                                                                                                                                            |
|  54 |     95.192714 |     36.894760 | Kent Elson Sorgon                                                                                                                                                     |
|  55 |    354.113823 |     83.559570 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  56 |    128.583464 |    688.266493 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|  57 |    410.086595 |    317.383569 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
|  58 |     49.385900 |    219.730330 | T. Michael Keesey                                                                                                                                                     |
|  59 |    799.499284 |     66.127273 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  60 |    162.485361 |    571.242601 | Jagged Fang Designs                                                                                                                                                   |
|  61 |    375.527682 |    698.072372 | Ingo Braasch                                                                                                                                                          |
|  62 |    404.882543 |    491.390144 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  63 |    760.936583 |    506.925248 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
|  64 |    957.177573 |    218.229981 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  65 |    474.022063 |     53.838226 | Beth Reinke                                                                                                                                                           |
|  66 |     68.415364 |    428.172030 | Roberto Díaz Sibaja                                                                                                                                                   |
|  67 |    773.636163 |    569.156421 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  68 |    502.554739 |    653.540379 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
|  69 |    235.509705 |    769.536802 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  70 |    100.798794 |    293.966382 | Chris huh                                                                                                                                                             |
|  71 |    974.192050 |    292.235163 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  72 |    765.124737 |    658.870538 | NA                                                                                                                                                                    |
|  73 |    857.591986 |    707.356767 | CNZdenek                                                                                                                                                              |
|  74 |    481.681572 |    630.883940 | Jagged Fang Designs                                                                                                                                                   |
|  75 |    163.652918 |    330.332825 | Scott Hartman                                                                                                                                                         |
|  76 |    753.884899 |     27.793054 | Chris huh                                                                                                                                                             |
|  77 |    332.600097 |    223.065612 | Emily Jane McTavish                                                                                                                                                   |
|  78 |    649.790501 |    149.115255 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  79 |    857.389931 |    166.528397 | Elisabeth Östman                                                                                                                                                      |
|  80 |    720.950978 |    197.928083 | Matt Crook                                                                                                                                                            |
|  81 |    994.673864 |     57.652589 | Jessica Anne Miller                                                                                                                                                   |
|  82 |    717.585735 |     71.101322 | Zimices                                                                                                                                                               |
|  83 |    897.393617 |    579.335209 | Margot Michaud                                                                                                                                                        |
|  84 |    947.740658 |    752.902480 | Dean Schnabel                                                                                                                                                         |
|  85 |    803.610270 |    358.444675 | Ferran Sayol                                                                                                                                                          |
|  86 |    474.201871 |    747.591341 | Gareth Monger                                                                                                                                                         |
|  87 |    183.332880 |    593.930090 | Ignacio Contreras                                                                                                                                                     |
|  88 |    388.345686 |    425.077017 | Matt Crook                                                                                                                                                            |
|  89 |    556.869335 |    122.198174 | Chuanixn Yu                                                                                                                                                           |
|  90 |    970.129073 |    298.499164 | Chris huh                                                                                                                                                             |
|  91 |    747.193506 |    774.188593 | Katie S. Collins                                                                                                                                                      |
|  92 |    468.206799 |    349.050394 | Gareth Monger                                                                                                                                                         |
|  93 |    731.389746 |    419.162283 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  94 |    178.663797 |    524.464058 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  95 |    531.938213 |    200.124235 | Jack Mayer Wood                                                                                                                                                       |
|  96 |    458.291611 |     80.291483 | Margot Michaud                                                                                                                                                        |
|  97 |    248.351574 |     66.618061 | Alex Slavenko                                                                                                                                                         |
|  98 |    279.658809 |    664.447889 | Carlos Cano-Barbacil                                                                                                                                                  |
|  99 |    218.007869 |    661.112753 | Erika Schumacher                                                                                                                                                      |
| 100 |    679.916865 |      4.130425 | Margot Michaud                                                                                                                                                        |
| 101 |    779.693911 |      8.597182 | Smokeybjb                                                                                                                                                             |
| 102 |    130.237163 |    241.950066 | Tyler McCraney                                                                                                                                                        |
| 103 |    823.961333 |    773.035328 | Gareth Monger                                                                                                                                                         |
| 104 |    757.337665 |    401.174878 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 105 |    458.703181 |    521.014871 | Gareth Monger                                                                                                                                                         |
| 106 |    446.981134 |      7.881146 | Chloé Schmidt                                                                                                                                                         |
| 107 |    521.290992 |    261.916999 | Sarah Werning                                                                                                                                                         |
| 108 |    585.916186 |    103.261004 | Zimices                                                                                                                                                               |
| 109 |   1001.802672 |    763.505134 | NA                                                                                                                                                                    |
| 110 |    364.587107 |    100.315417 | Verisimilus                                                                                                                                                           |
| 111 |    928.307930 |    429.279837 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 112 |    939.876902 |    407.619258 | Jaime Headden                                                                                                                                                         |
| 113 |    112.927797 |     83.415064 | Margot Michaud                                                                                                                                                        |
| 114 |    755.552824 |    202.197567 | Michelle Site                                                                                                                                                         |
| 115 |    594.361041 |    723.891880 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 116 |    233.175278 |     15.809883 | Katie S. Collins                                                                                                                                                      |
| 117 |    217.238946 |    556.940333 | Matt Dempsey                                                                                                                                                          |
| 118 |    235.632912 |     40.752765 | Matt Crook                                                                                                                                                            |
| 119 |    270.340323 |    122.072005 | Jon Hill                                                                                                                                                              |
| 120 |    662.117379 |    128.475409 | Scott Hartman                                                                                                                                                         |
| 121 |    416.951248 |    387.643986 | Javier Luque                                                                                                                                                          |
| 122 |    202.174028 |    342.693759 | Steven Traver                                                                                                                                                         |
| 123 |    745.396607 |    555.862866 | Chris huh                                                                                                                                                             |
| 124 |    487.816687 |    507.372372 | Andy Wilson                                                                                                                                                           |
| 125 |    547.203256 |    577.027958 | Steven Traver                                                                                                                                                         |
| 126 |    514.716376 |    562.116060 | T. Michael Keesey                                                                                                                                                     |
| 127 |    807.050112 |    175.647540 | Tyler McCraney                                                                                                                                                        |
| 128 |     69.535736 |    707.700418 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 129 |    198.834648 |    525.150960 | T. Michael Keesey                                                                                                                                                     |
| 130 |     22.662068 |    349.271409 | NA                                                                                                                                                                    |
| 131 |    821.438573 |    529.160350 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 132 |    989.274238 |    363.447509 | Joanna Wolfe                                                                                                                                                          |
| 133 |    341.869891 |    731.409071 | NA                                                                                                                                                                    |
| 134 |    829.518236 |     21.016983 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 135 |    905.874238 |     84.610916 | Caleb M. Brown                                                                                                                                                        |
| 136 |    652.888151 |    599.685773 | Matt Crook                                                                                                                                                            |
| 137 |    377.717267 |    396.092335 | Ignacio Contreras                                                                                                                                                     |
| 138 |    701.317139 |    787.308731 | Matt Crook                                                                                                                                                            |
| 139 |    416.230713 |    467.081129 | Margot Michaud                                                                                                                                                        |
| 140 |    338.516774 |    349.111577 | Anthony Caravaggi                                                                                                                                                     |
| 141 |    929.202372 |    444.151286 | T. Michael Keesey                                                                                                                                                     |
| 142 |     56.978201 |     78.509775 | Jaime Headden                                                                                                                                                         |
| 143 |    438.756268 |    784.037925 | Fernando Carezzano                                                                                                                                                    |
| 144 |    457.656740 |    348.180476 | T. Michael Keesey                                                                                                                                                     |
| 145 |    491.222499 |    163.204486 | T. Michael Keesey                                                                                                                                                     |
| 146 |     50.588304 |    102.619110 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 147 |   1000.622814 |    693.094549 | Jagged Fang Designs                                                                                                                                                   |
| 148 |    129.060562 |    191.794457 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 149 |    346.096157 |    163.664126 | Andy Wilson                                                                                                                                                           |
| 150 |    881.153477 |     42.231698 | Ferran Sayol                                                                                                                                                          |
| 151 |    454.141718 |    133.935805 | Fernando Campos De Domenico                                                                                                                                           |
| 152 |    660.580345 |    589.027766 | Felix Vaux                                                                                                                                                            |
| 153 |    481.295810 |    525.551840 | Rachel Shoop                                                                                                                                                          |
| 154 |    647.312507 |    312.507624 | Joanna Wolfe                                                                                                                                                          |
| 155 |    668.088673 |    270.995233 | Andy Wilson                                                                                                                                                           |
| 156 |    213.838300 |    617.446253 | Renato de Carvalho Ferreira                                                                                                                                           |
| 157 |    549.507832 |    670.020214 | Emily Willoughby                                                                                                                                                      |
| 158 |    889.485257 |    479.917402 | Zimices                                                                                                                                                               |
| 159 |    884.408996 |    169.613879 | Matt Crook                                                                                                                                                            |
| 160 |    767.845389 |    795.839485 | Collin Gross                                                                                                                                                          |
| 161 |    965.146044 |     30.869905 | Jagged Fang Designs                                                                                                                                                   |
| 162 |    675.409262 |    180.203612 | Kailah Thorn & Ben King                                                                                                                                               |
| 163 |    984.866204 |    671.343489 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 164 |    629.490005 |    719.229987 | Matt Crook                                                                                                                                                            |
| 165 |    616.196060 |    512.298881 | Birgit Lang                                                                                                                                                           |
| 166 |    187.495642 |     34.032088 | Steven Traver                                                                                                                                                         |
| 167 |     65.038818 |     95.459807 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
| 168 |    513.149243 |    729.115059 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 169 |    188.538755 |    629.488616 | Christina N. Hodson                                                                                                                                                   |
| 170 |    356.154388 |     61.715041 | NA                                                                                                                                                                    |
| 171 |    557.697651 |    791.451531 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 172 |    109.347957 |    715.922094 | NA                                                                                                                                                                    |
| 173 |    181.904658 |    538.494586 | Michelle Site                                                                                                                                                         |
| 174 |    912.534477 |    523.276267 | Emily Willoughby                                                                                                                                                      |
| 175 |    255.647122 |     90.469040 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 176 |    387.406333 |    197.311218 | Ferran Sayol                                                                                                                                                          |
| 177 |    469.772837 |    553.709499 | Jagged Fang Designs                                                                                                                                                   |
| 178 |    853.269721 |     82.708088 | Steven Traver                                                                                                                                                         |
| 179 |    536.501936 |    596.639265 | Zimices                                                                                                                                                               |
| 180 |    964.496054 |     83.347269 | Sharon Wegner-Larsen                                                                                                                                                  |
| 181 |     47.380791 |    364.016480 | JCGiron                                                                                                                                                               |
| 182 |    186.847410 |    304.862599 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 183 |    633.165925 |    280.097913 | Matt Crook                                                                                                                                                            |
| 184 |    706.729870 |    408.445802 | Jake Warner                                                                                                                                                           |
| 185 |    332.145598 |      7.157820 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 186 |    173.590083 |     19.226630 | M Kolmann                                                                                                                                                             |
| 187 |    976.758132 |    373.827616 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 188 |    696.467052 |     38.541350 | Carlos Cano-Barbacil                                                                                                                                                  |
| 189 |    194.615452 |    487.469273 | Margot Michaud                                                                                                                                                        |
| 190 |     53.472147 |    121.613405 | Matt Crook                                                                                                                                                            |
| 191 |    880.954814 |    550.785032 | Jiekun He                                                                                                                                                             |
| 192 |    708.531292 |    601.364159 | Roberto Díaz Sibaja                                                                                                                                                   |
| 193 |    211.314386 |    629.650091 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                            |
| 194 |    228.342107 |    349.402931 | Jake Warner                                                                                                                                                           |
| 195 |    540.252433 |    606.917749 | Andy Wilson                                                                                                                                                           |
| 196 |     14.960705 |    562.999935 | Mattia Menchetti                                                                                                                                                      |
| 197 |    601.643022 |    453.898314 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 198 |    316.685380 |    734.255251 | Tracy A. Heath                                                                                                                                                        |
| 199 |    677.527349 |    104.544628 | Javier Luque                                                                                                                                                          |
| 200 |    623.210044 |    132.697546 | Hugo Gruson                                                                                                                                                           |
| 201 |    644.245763 |    188.554201 | Sarah Werning                                                                                                                                                         |
| 202 |    533.804393 |    372.692901 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 203 |    101.656120 |    788.888967 | Matt Dempsey                                                                                                                                                          |
| 204 |    383.969337 |    254.265618 | Matt Crook                                                                                                                                                            |
| 205 |    298.914255 |    411.421783 | Caleb M. Brown                                                                                                                                                        |
| 206 |    986.434822 |      8.092270 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 207 |    472.158693 |    471.114390 | Mette Aumala                                                                                                                                                          |
| 208 |    645.479812 |    175.912048 | Collin Gross                                                                                                                                                          |
| 209 |    818.283932 |     83.810826 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 210 |    835.665428 |     69.002958 | C. Camilo Julián-Caballero                                                                                                                                            |
| 211 |    547.783435 |    231.605906 | CNZdenek                                                                                                                                                              |
| 212 |    182.006616 |    561.905883 | Marmelad                                                                                                                                                              |
| 213 |    342.447977 |    151.024996 | Gareth Monger                                                                                                                                                         |
| 214 |    695.221944 |    417.423049 | Tracy A. Heath                                                                                                                                                        |
| 215 |    155.434561 |    509.430893 | TaraTaylorDesign                                                                                                                                                      |
| 216 |    583.074076 |    696.650702 | Chris huh                                                                                                                                                             |
| 217 |    321.185787 |    719.348737 | Sarah Werning                                                                                                                                                         |
| 218 |    786.108552 |    313.550012 | NA                                                                                                                                                                    |
| 219 |     34.291244 |    482.238700 | Margot Michaud                                                                                                                                                        |
| 220 |    433.375042 |    547.094817 | Erika Schumacher                                                                                                                                                      |
| 221 |    603.576696 |    519.755166 | Amanda Katzer                                                                                                                                                         |
| 222 |    265.347382 |      8.585608 | FunkMonk                                                                                                                                                              |
| 223 |    553.223895 |    678.199314 | Steven Traver                                                                                                                                                         |
| 224 |    115.459824 |    227.485878 | Zimices                                                                                                                                                               |
| 225 |    632.385709 |     99.393439 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 226 |     75.099474 |    318.962932 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 227 |     91.676508 |     90.705560 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 228 |    840.661739 |    360.034574 | Gareth Monger                                                                                                                                                         |
| 229 |    169.725614 |    622.533440 | Cristina Guijarro                                                                                                                                                     |
| 230 |     56.235188 |    599.178786 | Zimices                                                                                                                                                               |
| 231 |    115.617162 |    256.618604 | C. Camilo Julián-Caballero                                                                                                                                            |
| 232 |     35.568036 |    791.367126 | Andrew A. Farke                                                                                                                                                       |
| 233 |    416.765937 |    449.783453 | NA                                                                                                                                                                    |
| 234 |     98.322457 |    470.740198 | Erika Schumacher                                                                                                                                                      |
| 235 |    917.522934 |    495.402032 | Tasman Dixon                                                                                                                                                          |
| 236 |    798.721692 |    320.758123 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 237 |    667.196029 |     93.364380 | Birgit Lang                                                                                                                                                           |
| 238 |     18.019324 |    508.530784 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 239 |     76.240164 |    625.786891 | Gareth Monger                                                                                                                                                         |
| 240 |    865.146763 |    212.030709 | Tracy A. Heath                                                                                                                                                        |
| 241 |    350.010122 |    441.381694 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 242 |    927.374064 |     11.015808 | Jaime Headden                                                                                                                                                         |
| 243 |    281.993956 |    397.276710 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 244 |    362.873511 |      6.505088 | Matt Martyniuk                                                                                                                                                        |
| 245 |    565.534071 |    185.797855 | Gareth Monger                                                                                                                                                         |
| 246 |    522.703660 |    182.457660 | Yan Wong                                                                                                                                                              |
| 247 |     20.321403 |     68.382213 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 248 |    112.481684 |    460.148544 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 249 |    198.489781 |    793.737019 | NA                                                                                                                                                                    |
| 250 |     12.471363 |    102.725065 | Richard J. Harris                                                                                                                                                     |
| 251 |    124.427907 |     99.817536 | Dean Schnabel                                                                                                                                                         |
| 252 |    878.530996 |    101.794826 | L. Shyamal                                                                                                                                                            |
| 253 |    476.957982 |    444.535794 | Margot Michaud                                                                                                                                                        |
| 254 |    815.534688 |    458.397491 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 255 |    104.480420 |    114.312674 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 256 |    706.691849 |    369.410395 | Zimices                                                                                                                                                               |
| 257 |     30.150091 |    691.793209 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 258 |    117.296893 |    415.875102 | Margot Michaud                                                                                                                                                        |
| 259 |    573.323302 |    650.669649 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 260 |    823.801670 |     42.102175 | Carlos Cano-Barbacil                                                                                                                                                  |
| 261 |    823.964227 |    165.483334 | B. Duygu Özpolat                                                                                                                                                      |
| 262 |    308.862688 |    152.032538 | Ferran Sayol                                                                                                                                                          |
| 263 |    662.746351 |    749.924295 | Tasman Dixon                                                                                                                                                          |
| 264 |    369.902940 |    326.561444 | Tasman Dixon                                                                                                                                                          |
| 265 |    167.936295 |      9.158406 | Ignacio Contreras                                                                                                                                                     |
| 266 |    852.105829 |     23.346955 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 267 |    610.666148 |    198.681614 | Andy Wilson                                                                                                                                                           |
| 268 |    155.067064 |    445.779656 | Taro Maeda                                                                                                                                                            |
| 269 |    547.395997 |    564.951627 | Milton Tan                                                                                                                                                            |
| 270 |    260.768167 |    723.526821 | Steven Traver                                                                                                                                                         |
| 271 |    928.467166 |    503.827758 | Scott Hartman                                                                                                                                                         |
| 272 |    378.585589 |    539.235701 | Mathilde Cordellier                                                                                                                                                   |
| 273 |     17.999289 |    680.240945 | NA                                                                                                                                                                    |
| 274 |     14.466520 |    371.942342 | NA                                                                                                                                                                    |
| 275 |    154.369141 |     27.677572 | Andy Wilson                                                                                                                                                           |
| 276 |    508.081004 |    529.964091 | T. Michael Keesey                                                                                                                                                     |
| 277 |    408.715018 |    103.603886 | Jagged Fang Designs                                                                                                                                                   |
| 278 |    654.697856 |    354.305033 | Birgit Lang                                                                                                                                                           |
| 279 |    817.090151 |     45.739801 | Matt Martyniuk                                                                                                                                                        |
| 280 |    389.220445 |    412.144315 | Steven Coombs                                                                                                                                                         |
| 281 |    882.378459 |    358.570292 | Margot Michaud                                                                                                                                                        |
| 282 |    807.537127 |    428.131817 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 283 |    458.223014 |    670.884266 | Kanchi Nanjo                                                                                                                                                          |
| 284 |    131.263600 |     14.038201 | Tasman Dixon                                                                                                                                                          |
| 285 |    350.399264 |    200.032810 | Ferran Sayol                                                                                                                                                          |
| 286 |    769.387248 |    424.078997 | NA                                                                                                                                                                    |
| 287 |    751.467195 |    448.163350 | Chris huh                                                                                                                                                             |
| 288 |    722.914271 |    652.746899 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 289 |    788.747392 |    541.467360 | Christoph Schomburg                                                                                                                                                   |
| 290 |    981.998588 |    576.291515 | Zimices                                                                                                                                                               |
| 291 |    904.433609 |    237.154236 | Birgit Lang                                                                                                                                                           |
| 292 |    434.258221 |    425.642160 | Chris huh                                                                                                                                                             |
| 293 |    633.447833 |    471.743272 | Collin Gross                                                                                                                                                          |
| 294 |    536.985550 |    217.308651 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 295 |    455.813110 |    714.566514 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 296 |    800.481297 |    695.029524 | Ieuan Jones                                                                                                                                                           |
| 297 |    598.258482 |    515.197956 | Jagged Fang Designs                                                                                                                                                   |
| 298 |    698.454494 |     88.037195 | NA                                                                                                                                                                    |
| 299 |    599.433734 |    552.789813 | Christina N. Hodson                                                                                                                                                   |
| 300 |    914.791836 |    697.107179 | Zimices                                                                                                                                                               |
| 301 |    841.143015 |    755.424551 | Matt Crook                                                                                                                                                            |
| 302 |    598.424027 |    243.519988 | Margot Michaud                                                                                                                                                        |
| 303 |    412.039350 |    435.740234 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 304 |    257.266054 |     25.652583 | Margot Michaud                                                                                                                                                        |
| 305 |    267.835710 |     60.350903 | John Conway                                                                                                                                                           |
| 306 |    706.802069 |    776.225429 | NA                                                                                                                                                                    |
| 307 |   1008.416600 |    204.525267 | NA                                                                                                                                                                    |
| 308 |    699.831728 |    375.088505 | Christoph Schomburg                                                                                                                                                   |
| 309 |      4.637152 |    689.408614 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 310 |     91.802962 |    334.661593 | Christoph Schomburg                                                                                                                                                   |
| 311 |    459.061944 |    284.321608 | T. Michael Keesey                                                                                                                                                     |
| 312 |    784.811707 |    653.067537 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 313 |    573.768543 |      9.586530 | NA                                                                                                                                                                    |
| 314 |    482.751400 |    717.265512 | Margot Michaud                                                                                                                                                        |
| 315 |    451.571094 |    163.645594 | Josefine Bohr Brask                                                                                                                                                   |
| 316 |    503.510434 |    751.135992 | Andy Wilson                                                                                                                                                           |
| 317 |    342.018500 |    449.843397 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 318 |    595.525515 |    537.661819 | David Orr                                                                                                                                                             |
| 319 |    439.530164 |     60.175128 | Steven Traver                                                                                                                                                         |
| 320 |     31.387602 |    285.965797 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 321 |    289.980252 |    550.794433 | Smokeybjb                                                                                                                                                             |
| 322 |   1014.160018 |    158.332858 | Birgit Lang                                                                                                                                                           |
| 323 |     51.260057 |    469.057604 | Gareth Monger                                                                                                                                                         |
| 324 |     98.110991 |    706.816508 | Jessica Anne Miller                                                                                                                                                   |
| 325 |     24.683040 |    587.151284 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 326 |    813.649711 |    479.946610 | Cesar Julian                                                                                                                                                          |
| 327 |    846.103761 |    425.245575 | Felix Vaux and Steven A. Trewick                                                                                                                                      |
| 328 |   1016.460077 |    325.034538 | NA                                                                                                                                                                    |
| 329 |   1004.503724 |    251.118621 | Andy Wilson                                                                                                                                                           |
| 330 |   1008.037067 |    410.134300 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 331 |   1014.857609 |     25.792517 | NA                                                                                                                                                                    |
| 332 |    428.177548 |    172.839484 | Zimices                                                                                                                                                               |
| 333 |    304.717541 |    246.227800 | Andrew A. Farke                                                                                                                                                       |
| 334 |    248.758817 |    361.469883 | Carlos Cano-Barbacil                                                                                                                                                  |
| 335 |    686.004910 |    303.535890 | NA                                                                                                                                                                    |
| 336 |    420.795514 |    640.998475 | FunkMonk                                                                                                                                                              |
| 337 |    259.720411 |    513.533813 | Jagged Fang Designs                                                                                                                                                   |
| 338 |    339.240557 |    414.575792 | Dean Schnabel                                                                                                                                                         |
| 339 |    794.570960 |     45.810031 | Felix Vaux                                                                                                                                                            |
| 340 |    683.334902 |    786.106808 | Zimices                                                                                                                                                               |
| 341 |    832.168433 |    187.726847 | \[unknown\]                                                                                                                                                           |
| 342 |    392.845891 |    171.041705 | Matt Crook                                                                                                                                                            |
| 343 |     34.383124 |    591.796466 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 344 |    634.586115 |    584.064000 | Dean Schnabel                                                                                                                                                         |
| 345 |    746.002204 |    735.002286 | Matt Crook                                                                                                                                                            |
| 346 |    615.615258 |    665.390587 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 347 |     90.583029 |    788.328578 | Michelle Site                                                                                                                                                         |
| 348 |    962.731882 |     47.819181 | Berivan Temiz                                                                                                                                                         |
| 349 |     35.489476 |    613.450563 | Steven Traver                                                                                                                                                         |
| 350 |    428.755028 |    437.609661 | Kanchi Nanjo                                                                                                                                                          |
| 351 |    573.201778 |    422.513347 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 352 |    599.115827 |    528.153007 | Jagged Fang Designs                                                                                                                                                   |
| 353 |   1017.309914 |    718.857948 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 354 |    142.158192 |    718.123604 | C. Camilo Julián-Caballero                                                                                                                                            |
| 355 |    120.754704 |    486.163910 | Maha Ghazal                                                                                                                                                           |
| 356 |   1013.520530 |    279.321644 | Zimices                                                                                                                                                               |
| 357 |    340.239901 |    222.579053 | Cesar Julian                                                                                                                                                          |
| 358 |    631.778861 |    494.401824 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 359 |    899.196733 |     70.163087 | NASA                                                                                                                                                                  |
| 360 |     28.508140 |    170.396636 | Ferran Sayol                                                                                                                                                          |
| 361 |     34.528945 |    546.389804 | Abraão Leite                                                                                                                                                          |
| 362 |    911.473729 |    551.493838 | Elizabeth Parker                                                                                                                                                      |
| 363 |    846.352181 |    250.605600 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 364 |    134.356732 |    178.877153 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 365 |    611.114282 |    471.389995 | Steven Traver                                                                                                                                                         |
| 366 |    529.676327 |    104.570847 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 367 |    418.340795 |    486.562237 | Tracy A. Heath                                                                                                                                                        |
| 368 |    903.537352 |    191.326438 | Steven Traver                                                                                                                                                         |
| 369 |    892.525397 |    147.985210 | Zimices                                                                                                                                                               |
| 370 |    656.739929 |    577.587255 | Ferran Sayol                                                                                                                                                          |
| 371 |    182.095347 |    585.993765 | Markus A. Grohme                                                                                                                                                      |
| 372 |    430.771724 |    456.047039 | C. Camilo Julián-Caballero                                                                                                                                            |
| 373 |    364.107022 |    481.997052 | NA                                                                                                                                                                    |
| 374 |     12.689144 |    139.754747 | Emily Willoughby                                                                                                                                                      |
| 375 |    922.879792 |    655.640653 | Jagged Fang Designs                                                                                                                                                   |
| 376 |    830.990421 |     90.859696 | Andy Wilson                                                                                                                                                           |
| 377 |    840.041384 |    354.811184 | Alex Slavenko                                                                                                                                                         |
| 378 |    961.125457 |    412.194879 | Kimberly Haddrell                                                                                                                                                     |
| 379 |    550.059232 |    612.977645 | Margot Michaud                                                                                                                                                        |
| 380 |    909.351412 |    689.678813 | Scott Hartman                                                                                                                                                         |
| 381 |    891.328819 |    100.608075 | Michael Scroggie                                                                                                                                                      |
| 382 |    448.391554 |    363.447670 | Jagged Fang Designs                                                                                                                                                   |
| 383 |     75.859391 |     99.500551 | Steven Traver                                                                                                                                                         |
| 384 |    974.144407 |     64.760398 | Margot Michaud                                                                                                                                                        |
| 385 |    881.464970 |    346.296293 | Margot Michaud                                                                                                                                                        |
| 386 |     17.551043 |    572.773778 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 387 |    315.161537 |    231.948637 | Dean Schnabel                                                                                                                                                         |
| 388 |    741.445331 |    157.729864 | NA                                                                                                                                                                    |
| 389 |    931.725153 |    794.551190 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 390 |    645.002022 |     96.784601 | Ferran Sayol                                                                                                                                                          |
| 391 |    895.826753 |    251.261370 | Ludwik Gąsiorowski                                                                                                                                                    |
| 392 |    690.648978 |    329.488372 | Steven Traver                                                                                                                                                         |
| 393 |    452.509045 |    486.424928 | Steven Traver                                                                                                                                                         |
| 394 |     42.847779 |    142.938865 | NA                                                                                                                                                                    |
| 395 |    902.586908 |    384.914691 | NA                                                                                                                                                                    |
| 396 |     19.508533 |     89.770023 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 397 |    276.093249 |    638.842124 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 398 |    302.264859 |    713.320901 | Zimices                                                                                                                                                               |
| 399 |    798.189688 |    527.752118 | Verdilak                                                                                                                                                              |
| 400 |    761.112138 |    606.354235 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 401 |    640.438688 |    455.419669 | Jagged Fang Designs                                                                                                                                                   |
| 402 |    560.316403 |    229.735371 | Matt Martyniuk                                                                                                                                                        |
| 403 |    436.056350 |    729.604217 | Zimices                                                                                                                                                               |
| 404 |    859.562023 |     74.968425 | Cesar Julian                                                                                                                                                          |
| 405 |    834.627084 |    472.708923 | Chris huh                                                                                                                                                             |
| 406 |    957.284077 |    787.961393 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 407 |    773.842082 |    545.402117 | Scott Hartman                                                                                                                                                         |
| 408 |    185.589445 |    213.478224 | Kanchi Nanjo                                                                                                                                                          |
| 409 |    148.105514 |    231.394660 | Steven Traver                                                                                                                                                         |
| 410 |    435.185726 |    354.202398 | Margot Michaud                                                                                                                                                        |
| 411 |    900.480715 |    729.261980 | T. Michael Keesey                                                                                                                                                     |
| 412 |     26.106153 |    444.132470 | Kamil S. Jaron                                                                                                                                                        |
| 413 |    544.837602 |    174.401641 | Margot Michaud                                                                                                                                                        |
| 414 |    277.384316 |    523.023672 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 415 |    490.901243 |     87.135433 | Zimices                                                                                                                                                               |
| 416 |    532.841564 |    247.956345 | Jonathan Wells                                                                                                                                                        |
| 417 |    297.596633 |     78.265439 | Zimices                                                                                                                                                               |
| 418 |    637.691757 |    745.964441 | Andy Wilson                                                                                                                                                           |
| 419 |    428.577683 |    559.068605 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 420 |    564.226195 |    339.459042 | Danielle Alba                                                                                                                                                         |
| 421 |    134.136464 |    549.281079 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 422 |     42.651679 |     64.149626 | Ferran Sayol                                                                                                                                                          |
| 423 |     16.204413 |    744.199279 | Beth Reinke                                                                                                                                                           |
| 424 |     11.175328 |    291.737589 | Margot Michaud                                                                                                                                                        |
| 425 |    558.380845 |    199.744323 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 426 |    832.151599 |    463.348719 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 427 |    982.285193 |    549.406284 | mystica                                                                                                                                                               |
| 428 |     58.953686 |    635.662599 | Kristina Gagalova                                                                                                                                                     |
| 429 |    706.689132 |     46.536765 | Ignacio Contreras                                                                                                                                                     |
| 430 |    138.263135 |    620.071260 | Mattia Menchetti                                                                                                                                                      |
| 431 |    356.114608 |    313.286887 | Jiekun He                                                                                                                                                             |
| 432 |    764.484554 |    588.583945 | Chuanixn Yu                                                                                                                                                           |
| 433 |    588.052412 |    341.840037 | Jagged Fang Designs                                                                                                                                                   |
| 434 |    620.736666 |    418.186416 | Matt Crook                                                                                                                                                            |
| 435 |    641.957544 |    594.821193 | Scott Hartman                                                                                                                                                         |
| 436 |    475.443345 |    167.407361 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 437 |    428.921576 |    674.974448 | NA                                                                                                                                                                    |
| 438 |    750.908692 |     11.530206 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 439 |    127.186802 |    217.468319 | Margot Michaud                                                                                                                                                        |
| 440 |    154.591657 |    656.088750 | CNZdenek                                                                                                                                                              |
| 441 |    939.925305 |    256.445168 | Joanna Wolfe                                                                                                                                                          |
| 442 |     86.689042 |    273.781360 | Jagged Fang Designs                                                                                                                                                   |
| 443 |    147.158240 |    270.002877 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 444 |    568.768204 |    237.611636 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 445 |    425.097462 |    163.424621 | Matt Celeskey                                                                                                                                                         |
| 446 |    369.225905 |    723.129170 | Gareth Monger                                                                                                                                                         |
| 447 |    924.774635 |    481.908571 | Steven Coombs                                                                                                                                                         |
| 448 |    267.914031 |    469.325343 | Jagged Fang Designs                                                                                                                                                   |
| 449 |     98.094200 |    254.278353 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 450 |    483.323691 |     14.955623 | Jagged Fang Designs                                                                                                                                                   |
| 451 |    663.482435 |    106.093683 | Steven Traver                                                                                                                                                         |
| 452 |    543.927224 |    526.317535 | Markus A. Grohme                                                                                                                                                      |
| 453 |     37.816356 |      8.822352 | Margot Michaud                                                                                                                                                        |
| 454 |    792.068604 |    762.615559 | T. Michael Keesey                                                                                                                                                     |
| 455 |    268.384556 |    358.402643 | Iain Reid                                                                                                                                                             |
| 456 |    476.229202 |     65.300296 | Zimices                                                                                                                                                               |
| 457 |    199.028295 |    541.215388 | Margot Michaud                                                                                                                                                        |
| 458 |    722.319969 |    391.663747 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                  |
| 459 |    760.128582 |    383.168668 | Jagged Fang Designs                                                                                                                                                   |
| 460 |    180.199963 |    603.806356 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 461 |      8.708501 |    490.453993 | Mattia Menchetti                                                                                                                                                      |
| 462 |    898.108458 |    797.700356 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 463 |    403.770076 |     19.998800 | Jagged Fang Designs                                                                                                                                                   |
| 464 |    781.803589 |    449.165624 | Margot Michaud                                                                                                                                                        |
| 465 |    210.275539 |    773.300881 | Rachel Shoop                                                                                                                                                          |
| 466 |      8.208732 |    790.440502 | Margot Michaud                                                                                                                                                        |
| 467 |    756.728607 |    328.767496 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 468 |    445.082868 |    125.130057 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 469 |    772.510378 |     49.685760 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 470 |     31.620752 |    104.295144 | Jaime Headden                                                                                                                                                         |
| 471 |    145.146043 |    351.271898 | Chris huh                                                                                                                                                             |
| 472 |    382.592790 |    360.415170 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 473 |    507.229638 |    232.031889 | T. Michael Keesey                                                                                                                                                     |
| 474 |    957.720454 |    230.668277 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 475 |    732.138073 |     60.834232 | Kai R. Caspar                                                                                                                                                         |
| 476 |    478.441007 |    782.164393 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 477 |    812.603367 |    150.323792 | NA                                                                                                                                                                    |
| 478 |    761.384588 |    342.169295 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 479 |    404.598671 |    173.958152 | Christoph Schomburg                                                                                                                                                   |
| 480 |    187.408099 |     11.241517 | Carlos Cano-Barbacil                                                                                                                                                  |
| 481 |   1007.291669 |    356.064999 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 482 |    609.792660 |    139.784056 | Matt Crook                                                                                                                                                            |
| 483 |    853.048932 |    151.006993 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 484 |     20.189029 |    545.503600 | Birgit Lang                                                                                                                                                           |
| 485 |    532.349943 |    127.276101 | Dean Schnabel                                                                                                                                                         |
| 486 |    602.906644 |    500.706640 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 487 |    710.882044 |    672.819699 | Tracy A. Heath                                                                                                                                                        |
| 488 |   1000.934702 |     26.229158 | Mathew Wedel                                                                                                                                                          |
| 489 |    415.772678 |     76.629142 | Tasman Dixon                                                                                                                                                          |
| 490 |    583.173076 |    174.297592 | xgirouxb                                                                                                                                                              |
| 491 |     45.594002 |     26.439013 | Shyamal                                                                                                                                                               |
| 492 |    258.712875 |    479.078188 | Markus A. Grohme                                                                                                                                                      |
| 493 |    216.871841 |     55.952021 | Markus A. Grohme                                                                                                                                                      |
| 494 |    184.432665 |    494.326349 | Scott Hartman                                                                                                                                                         |
| 495 |   1008.574307 |    558.188972 | CNZdenek                                                                                                                                                              |
| 496 |    854.650158 |    728.263601 | Skye McDavid                                                                                                                                                          |
| 497 |    294.171798 |    637.966565 | Lily Hughes                                                                                                                                                           |
| 498 |    818.218735 |    755.586720 | Jagged Fang Designs                                                                                                                                                   |
| 499 |    935.980028 |     49.842199 | FunkMonk                                                                                                                                                              |
| 500 |    992.272780 |    239.482758 | Ferran Sayol                                                                                                                                                          |
| 501 |    701.966034 |    764.480166 | NA                                                                                                                                                                    |
| 502 |    888.012855 |    510.864054 | Jagged Fang Designs                                                                                                                                                   |
| 503 |    584.243242 |    127.406753 | Zimices                                                                                                                                                               |
| 504 |    372.995333 |    785.495777 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 505 |    831.650655 |    287.056614 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 506 |    458.181153 |    770.411457 | Dean Schnabel                                                                                                                                                         |
| 507 |    677.243270 |    221.376733 | B. Duygu Özpolat                                                                                                                                                      |
| 508 |    466.992892 |    123.951151 | Martin R. Smith                                                                                                                                                       |
| 509 |     90.478587 |    314.042805 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 510 |    528.635587 |    603.817522 | Ben Liebeskind                                                                                                                                                        |
| 511 |    843.494465 |    739.953262 | Steven Traver                                                                                                                                                         |
| 512 |    998.415070 |    387.151082 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 513 |    689.150610 |    376.415641 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 514 |    600.766662 |    741.067102 | Ferran Sayol                                                                                                                                                          |
| 515 |    494.582910 |    260.276636 | NA                                                                                                                                                                    |
| 516 |    895.228982 |    345.554917 | Zimices                                                                                                                                                               |
| 517 |    381.914038 |    182.647825 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 518 |    183.236985 |    345.424226 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 519 |    389.041169 |    676.978437 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 520 |    165.159665 |    702.440363 | Beth Reinke                                                                                                                                                           |
| 521 |    269.857188 |    678.280764 | Matt Crook                                                                                                                                                            |
| 522 |    917.987815 |    731.501846 | Ferran Sayol                                                                                                                                                          |
| 523 |    376.645258 |    149.691056 | Chris huh                                                                                                                                                             |
| 524 |     18.458840 |    159.114500 | Natalie Claunch                                                                                                                                                       |
| 525 |    739.556434 |    332.289878 | Christoph Schomburg                                                                                                                                                   |
| 526 |    515.207872 |    602.510859 | Scott Hartman                                                                                                                                                         |
| 527 |    945.888930 |    390.132584 | NA                                                                                                                                                                    |
| 528 |   1012.018055 |    539.055472 | Aadx                                                                                                                                                                  |
| 529 |    699.096634 |    241.814893 | Maija Karala                                                                                                                                                          |
| 530 |    750.473907 |     49.209126 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 531 |    369.177273 |    254.773047 | T. Michael Keesey                                                                                                                                                     |
| 532 |    888.540832 |    403.059726 | Jaime Headden                                                                                                                                                         |
| 533 |    538.501807 |     37.153474 | Steven Traver                                                                                                                                                         |
| 534 |    365.247299 |    416.513834 | Matt Crook                                                                                                                                                            |
| 535 |    970.796368 |    234.847932 | Mark Witton                                                                                                                                                           |
| 536 |    803.800250 |    597.464496 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 537 |   1014.734588 |    734.343808 | Margot Michaud                                                                                                                                                        |
| 538 |    504.525892 |    587.635519 | Carlos Cano-Barbacil                                                                                                                                                  |
| 539 |    316.268207 |    283.175756 | Margot Michaud                                                                                                                                                        |
| 540 |    749.754730 |    536.982963 | NA                                                                                                                                                                    |
| 541 |    914.248963 |    504.634355 | Jagged Fang Designs                                                                                                                                                   |
| 542 |    486.413747 |    149.413973 | Margot Michaud                                                                                                                                                        |
| 543 |    310.155864 |    522.652706 | Margot Michaud                                                                                                                                                        |
| 544 |    616.627750 |    794.138870 | Christoph Schomburg                                                                                                                                                   |
| 545 |     35.154970 |    367.914010 | Harold N Eyster                                                                                                                                                       |
| 546 |    967.408278 |    541.061597 | NA                                                                                                                                                                    |
| 547 |     86.916780 |    217.866108 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 548 |    492.305297 |    545.058366 | Zimices                                                                                                                                                               |
| 549 |    837.844849 |    684.379387 | Zimices                                                                                                                                                               |
| 550 |    549.283658 |    643.146880 | NA                                                                                                                                                                    |
| 551 |   1001.862699 |    644.347018 | Maija Karala                                                                                                                                                          |
| 552 |    182.428319 |    550.281904 | Christoph Schomburg                                                                                                                                                   |
| 553 |    739.258698 |    441.727145 | Tauana J. Cunha                                                                                                                                                       |
| 554 |    918.596813 |    531.968515 | Jagged Fang Designs                                                                                                                                                   |
| 555 |    161.948676 |    460.366219 | Andy Wilson                                                                                                                                                           |
| 556 |     19.184659 |     42.012685 | Matt Crook                                                                                                                                                            |
| 557 |    985.014629 |    405.564277 | NA                                                                                                                                                                    |
| 558 |    804.149261 |    779.556514 | Caleb M. Brown                                                                                                                                                        |
| 559 |    254.515505 |     55.543026 | Markus A. Grohme                                                                                                                                                      |
| 560 |    899.485141 |    456.282286 | Sarah Werning                                                                                                                                                         |
| 561 |    579.476088 |    522.478944 | Jakovche                                                                                                                                                              |
| 562 |    126.173840 |    786.140457 | Nobu Tamura                                                                                                                                                           |
| 563 |    904.395866 |    564.373885 | Christine Axon                                                                                                                                                        |
| 564 |    121.113990 |    208.177788 | Scott Hartman                                                                                                                                                         |
| 565 |     35.559392 |    380.954086 | Matt Hayes                                                                                                                                                            |
| 566 |    160.787952 |    710.421039 | Milton Tan                                                                                                                                                            |
| 567 |    133.233936 |    225.666640 | Michelle Site                                                                                                                                                         |
| 568 |    422.650514 |    363.349919 | Matt Martyniuk                                                                                                                                                        |
| 569 |    654.343656 |    754.443094 | Markus A. Grohme                                                                                                                                                      |
| 570 |    359.673122 |    781.664943 | Matt Crook                                                                                                                                                            |
| 571 |    692.178802 |    154.923630 | Andy Wilson                                                                                                                                                           |
| 572 |    383.940589 |    505.129826 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 573 |    362.491501 |    428.110271 | Darius Nau                                                                                                                                                            |
| 574 |    220.051355 |     86.629791 | Felix Vaux                                                                                                                                                            |
| 575 |    114.478963 |    596.449518 | Ingo Braasch                                                                                                                                                          |
| 576 |    531.526139 |    551.696383 | FunkMonk                                                                                                                                                              |
| 577 |    502.695228 |    446.017745 | Jagged Fang Designs                                                                                                                                                   |
| 578 |    275.459582 |    513.022265 | Cesar Julian                                                                                                                                                          |
| 579 |    592.272204 |    430.830512 | Melissa Broussard                                                                                                                                                     |
| 580 |    220.346714 |    526.743193 | Matt Crook                                                                                                                                                            |
| 581 |    997.747712 |    571.432815 | Matt Crook                                                                                                                                                            |
| 582 |    471.178889 |     12.432978 | Yan Wong                                                                                                                                                              |
| 583 |    158.902723 |    534.398994 |                                                                                                                                                                       |
| 584 |    372.034045 |    236.162285 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 585 |    681.807603 |    393.186221 | NA                                                                                                                                                                    |
| 586 |    795.480497 |    582.795328 | Andy Wilson                                                                                                                                                           |
| 587 |    896.710601 |    602.369353 | T. Michael Keesey                                                                                                                                                     |
| 588 |    894.593882 |    197.552493 | Margot Michaud                                                                                                                                                        |
| 589 |    201.957213 |    681.362910 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 590 |    997.226966 |    140.169066 | Alexandre Vong                                                                                                                                                        |
| 591 |    896.368344 |    125.040733 | Matt Crook                                                                                                                                                            |
| 592 |    606.547715 |    355.044402 | Jagged Fang Designs                                                                                                                                                   |
| 593 |    665.900010 |    790.982421 | Sharon Wegner-Larsen                                                                                                                                                  |
| 594 |    398.462309 |    376.788884 | Steven Traver                                                                                                                                                         |
| 595 |    481.102195 |    731.885779 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 596 |    649.245997 |      6.352230 | Chloé Schmidt                                                                                                                                                         |
| 597 |    443.237651 |    282.417296 | Harold N Eyster                                                                                                                                                       |
| 598 |    561.973084 |    465.810688 | Matt Crook                                                                                                                                                            |
| 599 |     13.859778 |    471.770153 | Zimices                                                                                                                                                               |
| 600 |    918.848543 |    315.181742 | Steven Traver                                                                                                                                                         |
| 601 |    733.467839 |    794.427422 | Ignacio Contreras                                                                                                                                                     |
| 602 |    487.763984 |     99.670260 | Mattia Menchetti                                                                                                                                                      |
| 603 |    486.109803 |    178.383771 | Jagged Fang Designs                                                                                                                                                   |
| 604 |    530.835053 |    626.900408 | Jonathan Wells                                                                                                                                                        |
| 605 |    128.749260 |    445.741913 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 606 |    925.045335 |    744.409498 | FunkMonk                                                                                                                                                              |
| 607 |    458.202240 |    467.854804 | Ferran Sayol                                                                                                                                                          |
| 608 |    807.353295 |     94.827381 | Steven Traver                                                                                                                                                         |
| 609 |    356.137838 |    298.369533 | T. Michael Keesey                                                                                                                                                     |
| 610 |   1015.299040 |    234.706462 | Mathieu Basille                                                                                                                                                       |
| 611 |    867.923415 |    151.740067 | S.Martini                                                                                                                                                             |
| 612 |    489.281882 |    758.051372 | Mathieu Pélissié                                                                                                                                                      |
| 613 |    842.657682 |     44.095186 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 614 |     14.393135 |    390.276756 | Neil Kelley                                                                                                                                                           |
| 615 |    353.233822 |    264.268718 | NA                                                                                                                                                                    |
| 616 |    621.788680 |    566.900549 | Mathew Wedel                                                                                                                                                          |
| 617 |    386.854954 |    365.830880 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 618 |    366.476938 |    448.001243 | Matt Crook                                                                                                                                                            |
| 619 |    405.962039 |    724.368248 | Audrey Ely                                                                                                                                                            |
| 620 |    469.009265 |    190.207069 | Gareth Monger                                                                                                                                                         |
| 621 |    676.598705 |    144.778613 | Noah Schlottman                                                                                                                                                       |
| 622 |    272.924921 |    698.303888 | Margot Michaud                                                                                                                                                        |
| 623 |    510.608996 |    107.525678 | Margot Michaud                                                                                                                                                        |
| 624 |    550.335483 |    515.994976 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 625 |    719.235936 |    380.219339 | Gareth Monger                                                                                                                                                         |
| 626 |     88.617316 |    560.494138 | Matt Crook                                                                                                                                                            |
| 627 |    817.818332 |    727.824819 | Benjamint444                                                                                                                                                          |
| 628 |    766.176668 |    439.571066 | Kanchi Nanjo                                                                                                                                                          |
| 629 |    498.249165 |    181.284161 | Margot Michaud                                                                                                                                                        |
| 630 |    212.732259 |    144.153529 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 631 |    136.224216 |    512.510701 | Margot Michaud                                                                                                                                                        |
| 632 |    731.994821 |     87.575930 | Carlos Cano-Barbacil                                                                                                                                                  |
| 633 |    775.098761 |    535.766201 | Chase Brownstein                                                                                                                                                      |
| 634 |    744.460344 |    178.327024 | NA                                                                                                                                                                    |
| 635 |    875.701754 |    164.569480 | Jagged Fang Designs                                                                                                                                                   |
| 636 |    815.804175 |    293.607533 | Gareth Monger                                                                                                                                                         |
| 637 |    706.977238 |    181.699072 | NA                                                                                                                                                                    |
| 638 |    509.059652 |    197.350450 | Scott Hartman                                                                                                                                                         |
| 639 |     33.128218 |    457.159894 | L. Shyamal                                                                                                                                                            |
| 640 |     23.625491 |    256.901453 | Kanchi Nanjo                                                                                                                                                          |
| 641 |    441.749590 |    749.324574 | V. Deepak                                                                                                                                                             |
| 642 |    722.567570 |    233.348051 | Ferran Sayol                                                                                                                                                          |
| 643 |    437.404034 |    347.641498 | Tony Ayling                                                                                                                                                           |
| 644 |    384.079221 |    337.337643 | Steven Traver                                                                                                                                                         |
| 645 |    285.068363 |    535.227401 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 646 |    942.131450 |    787.470935 | Gareth Monger                                                                                                                                                         |
| 647 |    221.035093 |    682.970051 | Maija Karala                                                                                                                                                          |
| 648 |    934.116167 |     70.666860 | NA                                                                                                                                                                    |
| 649 |    309.879481 |    129.309736 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                         |
| 650 |     60.487084 |    625.580178 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 651 |     67.114250 |    759.980089 | Chris huh                                                                                                                                                             |
| 652 |    905.631850 |      6.106108 | Shyamal                                                                                                                                                               |
| 653 |    614.055130 |    441.606862 | Ignacio Contreras                                                                                                                                                     |
| 654 |    452.366053 |    591.130458 | Armin Reindl                                                                                                                                                          |
| 655 |    617.838766 |    281.762962 | Zimices                                                                                                                                                               |
| 656 |    460.811866 |    437.754234 | Lukasiniho                                                                                                                                                            |
| 657 |    317.769029 |     59.298190 | Steven Traver                                                                                                                                                         |
| 658 |    633.903581 |     71.380388 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 659 |    542.179222 |     23.099458 | Zimices                                                                                                                                                               |
| 660 |    151.516494 |    308.257909 | Michelle Site                                                                                                                                                         |
| 661 |    826.055814 |    494.957278 | Ludwik Gąsiorowski                                                                                                                                                    |
| 662 |    681.217736 |     68.458669 | Armin Reindl                                                                                                                                                          |
| 663 |    526.388616 |    225.843494 | Gareth Monger                                                                                                                                                         |
| 664 |    303.923614 |      9.705293 | M Kolmann                                                                                                                                                             |
| 665 |    830.729456 |    568.516786 | Ferran Sayol                                                                                                                                                          |
| 666 |    899.701290 |    180.311610 | Margot Michaud                                                                                                                                                        |
| 667 |    317.373040 |    445.357163 | Matt Crook                                                                                                                                                            |
| 668 |    380.253194 |    213.989205 | (after McCulloch 1908)                                                                                                                                                |
| 669 |    669.754667 |    423.647333 | Ingo Braasch                                                                                                                                                          |
| 670 |     60.865888 |    788.286861 | Birgit Lang                                                                                                                                                           |
| 671 |    523.884983 |    751.180512 | Gareth Monger                                                                                                                                                         |
| 672 |    253.338435 |     82.671971 | Pete Buchholz                                                                                                                                                         |
| 673 |    620.075916 |    735.736745 | Gareth Monger                                                                                                                                                         |
| 674 |   1012.594463 |     46.751323 | Andrew A. Farke                                                                                                                                                       |
| 675 |    861.364913 |    132.175847 | Mykle Hoban                                                                                                                                                           |
| 676 |    877.541369 |     63.458498 | Andy Wilson                                                                                                                                                           |
| 677 |    530.400031 |    433.473716 | Margot Michaud                                                                                                                                                        |
| 678 |    168.232226 |    608.075096 | Gareth Monger                                                                                                                                                         |
| 679 |    306.822086 |    277.048908 | Steven Traver                                                                                                                                                         |
| 680 |    862.188957 |    297.025367 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 681 |     88.141652 |    235.460012 | Matt Crook                                                                                                                                                            |
| 682 |     10.643177 |    345.341949 | Scott Hartman                                                                                                                                                         |
| 683 |    675.248834 |     80.966444 | Margot Michaud                                                                                                                                                        |
| 684 |    500.669713 |     73.572602 | Jagged Fang Designs                                                                                                                                                   |
| 685 |    515.656117 |    453.196420 | Matt Crook                                                                                                                                                            |
| 686 |    937.925745 |    471.577191 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 687 |    574.843668 |    703.267015 | Zimices                                                                                                                                                               |
| 688 |    183.098760 |    315.088007 | Sarah Werning                                                                                                                                                         |
| 689 |    354.969428 |    357.205525 | NA                                                                                                                                                                    |
| 690 |    632.540721 |    194.027729 | Melissa Broussard                                                                                                                                                     |
| 691 |     56.262065 |    714.443675 | Jagged Fang Designs                                                                                                                                                   |
| 692 |    510.921001 |    352.865615 | Scott Hartman                                                                                                                                                         |
| 693 |    697.972622 |    498.043611 | Matt Crook                                                                                                                                                            |
| 694 |    538.685664 |    745.886508 | Zimices                                                                                                                                                               |
| 695 |    562.543302 |    179.554439 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 696 |    267.214537 |    400.757543 | NA                                                                                                                                                                    |
| 697 |    546.388387 |    787.217650 | Agnello Picorelli                                                                                                                                                     |
| 698 |    616.468015 |    338.604587 | Lukasiniho                                                                                                                                                            |
| 699 |      8.694595 |    741.220905 | Tasman Dixon                                                                                                                                                          |
| 700 |    401.583549 |    540.119928 | Raven Amos                                                                                                                                                            |
| 701 |     13.372137 |    498.409131 | Steven Traver                                                                                                                                                         |
| 702 |      3.698891 |    566.272676 | Joanna Wolfe                                                                                                                                                          |
| 703 |    597.905220 |    442.832651 | Jagged Fang Designs                                                                                                                                                   |
| 704 |    200.389115 |    463.732078 | Gareth Monger                                                                                                                                                         |
| 705 |    771.425052 |    457.042886 | Peileppe                                                                                                                                                              |
| 706 |    206.151932 |    590.689179 | NA                                                                                                                                                                    |
| 707 |    463.884729 |    544.901314 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 708 |    436.034312 |    369.904548 | Matt Crook                                                                                                                                                            |
| 709 |    699.715775 |    141.896767 | Caleb M. Brown                                                                                                                                                        |
| 710 |      7.615398 |    765.984334 | Samanta Orellana                                                                                                                                                      |
| 711 |    304.279594 |    169.138935 | Scott Reid                                                                                                                                                            |
| 712 |    632.952567 |    649.679554 | Zimices                                                                                                                                                               |
| 713 |    891.560818 |    558.117064 | L. Shyamal                                                                                                                                                            |
| 714 |    136.661163 |    453.728594 | Wayne Decatur                                                                                                                                                         |
| 715 |   1019.783627 |    679.155496 | Gareth Monger                                                                                                                                                         |
| 716 |    765.455803 |    163.790435 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 717 |    483.888705 |    667.359927 | NA                                                                                                                                                                    |
| 718 |    664.215471 |    730.962725 | Andy Wilson                                                                                                                                                           |
| 719 |    540.744605 |     10.029193 | Steven Traver                                                                                                                                                         |
| 720 |    559.147965 |    219.963484 | Jagged Fang Designs                                                                                                                                                   |
| 721 |    684.538367 |     98.152143 | Frank Denota                                                                                                                                                          |
| 722 |    937.832517 |    530.942631 | Oscar Sanisidro                                                                                                                                                       |
| 723 |    816.907599 |    341.608743 | Dmitry Bogdanov                                                                                                                                                       |
| 724 |    402.273433 |     84.074032 | Steven Coombs                                                                                                                                                         |
| 725 |    347.172082 |    334.358024 | Margot Michaud                                                                                                                                                        |
| 726 |   1009.710659 |    389.752866 | Zimices                                                                                                                                                               |
| 727 |    911.817837 |    259.474014 | Scott Hartman                                                                                                                                                         |
| 728 |    695.803186 |    315.222896 | Tasman Dixon                                                                                                                                                          |
| 729 |    874.366228 |    140.079047 | Zimices                                                                                                                                                               |
| 730 |    284.680573 |    769.219251 | Zimices                                                                                                                                                               |
| 731 |    461.007429 |    531.655208 | Matt Crook                                                                                                                                                            |
| 732 |    193.996784 |    706.458934 | Christoph Schomburg                                                                                                                                                   |
| 733 |    200.520463 |    763.646513 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 734 |    135.401508 |    275.345900 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 735 |    498.894450 |    215.046849 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 736 |     56.888314 |    611.937815 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 737 |    778.335135 |    325.053765 | Chuanixn Yu                                                                                                                                                           |
| 738 |    890.829705 |    205.888246 | Zimices                                                                                                                                                               |
| 739 |    708.020489 |     82.308228 | Steven Traver                                                                                                                                                         |
| 740 |    723.431914 |    488.149859 | Ferran Sayol                                                                                                                                                          |
| 741 |    690.617109 |     60.732715 | Margot Michaud                                                                                                                                                        |
| 742 |    735.681483 |    166.317736 | Steven Traver                                                                                                                                                         |
| 743 |    711.696312 |    726.403432 | Gareth Monger                                                                                                                                                         |
| 744 |     69.524604 |    548.521688 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 745 |    356.370829 |    713.956554 | Chris huh                                                                                                                                                             |
| 746 |    389.569855 |     12.383660 | Matt Crook                                                                                                                                                            |
| 747 |    998.836361 |    208.187555 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 748 |    564.531448 |    446.160024 | Markus A. Grohme                                                                                                                                                      |
| 749 |    853.069654 |    370.972534 | Emily Willoughby                                                                                                                                                      |
| 750 |    752.352530 |    633.374140 | Mathieu Basille                                                                                                                                                       |
| 751 |    576.821733 |    680.154806 | Andy Wilson                                                                                                                                                           |
| 752 |     64.009696 |    617.103396 | Xavier Giroux-Bougard                                                                                                                                                 |
| 753 |    201.460699 |     52.222184 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 754 |     43.147709 |    782.882366 | Matt Crook                                                                                                                                                            |
| 755 |    147.410188 |    251.213584 | Jiekun He                                                                                                                                                             |
| 756 |    981.846436 |    776.429020 | Michelle Site                                                                                                                                                         |
| 757 |    393.868209 |    547.152365 | Lukasiniho                                                                                                                                                            |
| 758 |    139.237501 |    493.905725 | Collin Gross                                                                                                                                                          |
| 759 |    936.362808 |    733.295938 | Zimices                                                                                                                                                               |
| 760 |    524.697580 |    739.352548 | Kanchi Nanjo                                                                                                                                                          |
| 761 |    249.994574 |    482.951092 | Gareth Monger                                                                                                                                                         |
| 762 |    610.756951 |    490.440745 | Zimices                                                                                                                                                               |
| 763 |    234.115835 |    729.271427 | Jagged Fang Designs                                                                                                                                                   |
| 764 |    559.600736 |    623.677440 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 765 |     10.247095 |    628.320751 | Andrew A. Farke                                                                                                                                                       |
| 766 |   1009.421423 |     16.666168 | Margot Michaud                                                                                                                                                        |
| 767 |    627.911874 |    351.670526 | Margot Michaud                                                                                                                                                        |
| 768 |    536.664670 |    544.831882 | NA                                                                                                                                                                    |
| 769 |    597.192830 |    571.524462 | NA                                                                                                                                                                    |
| 770 |    155.286564 |    619.817001 | Chloé Schmidt                                                                                                                                                         |
| 771 |    118.492002 |    665.304063 | Felix Vaux                                                                                                                                                            |
| 772 |   1006.158394 |    675.635858 | T. Michael Keesey                                                                                                                                                     |
| 773 |    609.851652 |    117.888668 | Margot Michaud                                                                                                                                                        |
| 774 |    898.783048 |    739.470712 | Zimices                                                                                                                                                               |
| 775 |    621.818095 |    453.069251 | Matt Crook                                                                                                                                                            |
| 776 |    660.969771 |    307.521910 | Margot Michaud                                                                                                                                                        |
| 777 |    108.044595 |    571.927572 | Katie S. Collins                                                                                                                                                      |
| 778 |    849.792267 |    314.889293 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 779 |     12.691365 |    130.546955 | Steven Traver                                                                                                                                                         |
| 780 |     32.532792 |    301.210576 | Steven Traver                                                                                                                                                         |
| 781 |    574.218360 |    730.219923 | Maija Karala                                                                                                                                                          |
| 782 |    774.232096 |    711.991032 | NA                                                                                                                                                                    |
| 783 |    529.773019 |    618.902504 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 784 |    661.044931 |    719.509184 | Matt Crook                                                                                                                                                            |
| 785 |   1006.911944 |    608.900403 | Terpsichores                                                                                                                                                          |
| 786 |    475.203677 |     28.220487 | FunkMonk                                                                                                                                                              |
| 787 |    930.062576 |     95.676457 | Matt Crook                                                                                                                                                            |
| 788 |     71.073521 |    483.319524 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 789 |    568.489285 |    107.863683 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 790 |    901.879684 |    380.762454 | Manabu Sakamoto                                                                                                                                                       |
| 791 |     78.101764 |    256.907541 | Lukasiniho                                                                                                                                                            |
| 792 |    866.259268 |    738.902677 | Christoph Schomburg                                                                                                                                                   |
| 793 |    156.639694 |    734.567418 | Matt Crook                                                                                                                                                            |
| 794 |    678.217745 |    318.038785 | Jiekun He                                                                                                                                                             |
| 795 |     57.740426 |    392.175842 | wsnaccad                                                                                                                                                              |
| 796 |    123.345060 |    745.652771 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 797 |    570.693177 |    410.663571 | Margot Michaud                                                                                                                                                        |
| 798 |    169.587241 |    665.804460 | Chris huh                                                                                                                                                             |
| 799 |    218.515562 |     99.723402 | Zimices                                                                                                                                                               |
| 800 |    130.013655 |    709.158339 | Steven Traver                                                                                                                                                         |
| 801 |     18.658168 |    753.266534 | NA                                                                                                                                                                    |
| 802 |     83.197330 |    182.900740 | Ricardo Araújo                                                                                                                                                        |
| 803 |    341.396278 |    541.687494 | Jagged Fang Designs                                                                                                                                                   |
| 804 |    788.533925 |    158.020001 | Martin R. Smith                                                                                                                                                       |
| 805 |    495.249807 |    594.485134 | Jonathan Wells                                                                                                                                                        |
| 806 |    161.890267 |    284.533345 | NA                                                                                                                                                                    |
| 807 |     12.751681 |    231.716006 | T. Michael Keesey                                                                                                                                                     |
| 808 |    180.074166 |    200.926686 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 809 |    551.740907 |    382.997682 | Samanta Orellana                                                                                                                                                      |
| 810 |     15.965058 |    204.835007 | Emma Kissling                                                                                                                                                         |
| 811 |    806.521568 |    572.755507 | Mathew Wedel                                                                                                                                                          |
| 812 |    732.653920 |    211.160814 | Zimices                                                                                                                                                               |
| 813 |   1016.031329 |     74.116111 | Matt Crook                                                                                                                                                            |
| 814 |    730.521557 |    666.060085 | Zimices                                                                                                                                                               |
| 815 |    395.763346 |    470.694707 | Margot Michaud                                                                                                                                                        |
| 816 |    620.097356 |    270.176537 | L.M. Davalos                                                                                                                                                          |
| 817 |    876.517107 |    367.354271 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 818 |    914.023448 |     10.662699 | Jonathan Wells                                                                                                                                                        |
| 819 |    586.749541 |    252.028423 | Felix Vaux                                                                                                                                                            |
| 820 |    310.039141 |    792.439725 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 821 |     66.395245 |    163.809137 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 822 |    929.183329 |    711.116327 | Ferran Sayol                                                                                                                                                          |
| 823 |    729.583042 |    592.747484 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 824 |    648.402079 |    670.364829 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 825 |    962.565481 |    394.708532 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 826 |    888.952552 |    394.620377 | Scott Hartman                                                                                                                                                         |
| 827 |    253.415482 |    130.664258 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 828 |    436.711842 |    496.739503 | Margot Michaud                                                                                                                                                        |
| 829 |    206.358286 |    495.162839 | Margot Michaud                                                                                                                                                        |
| 830 |    459.387419 |    104.456165 | Yan Wong                                                                                                                                                              |
| 831 |    558.926276 |    598.340266 | Tauana J. Cunha                                                                                                                                                       |
| 832 |    262.754398 |    345.951148 | NA                                                                                                                                                                    |
| 833 |   1003.042311 |    687.710850 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 834 |     69.846011 |    372.770561 | Matt Crook                                                                                                                                                            |
| 835 |    340.350586 |    716.950550 | Taro Maeda                                                                                                                                                            |
| 836 |    391.458947 |    773.653758 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 837 |    834.503718 |     72.992485 | Dmitry Bogdanov                                                                                                                                                       |
| 838 |    449.186754 |    330.932000 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 839 |     59.652869 |    131.267879 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 840 |    385.155796 |     23.293191 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 841 |    993.882623 |    624.389994 | Cesar Julian                                                                                                                                                          |
| 842 |     60.461646 |    143.499372 | Collin Gross                                                                                                                                                          |
| 843 |    756.823302 |    222.583877 | Michelle Site                                                                                                                                                         |
| 844 |    721.147815 |    599.160570 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 845 |   1017.719656 |    637.554877 | Gopal Murali                                                                                                                                                          |
| 846 |    350.636692 |    184.819714 | FunkMonk                                                                                                                                                              |
| 847 |    414.501315 |    682.977061 | Gareth Monger                                                                                                                                                         |
| 848 |    897.635445 |     37.870684 | Zimices                                                                                                                                                               |
| 849 |     62.983886 |     13.572251 | Mathieu Basille                                                                                                                                                       |
| 850 |   1017.103601 |    265.638572 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 851 |    322.858499 |    390.591943 | Anthony Caravaggi                                                                                                                                                     |
| 852 |    825.443705 |    744.740314 | Zimices                                                                                                                                                               |
| 853 |    857.705541 |     60.178638 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                          |
| 854 |    546.239585 |    396.543184 | Ferran Sayol                                                                                                                                                          |
| 855 |    522.639996 |    518.947846 | Matt Crook                                                                                                                                                            |
| 856 |    160.695061 |    781.491991 | NA                                                                                                                                                                    |
| 857 |    205.351571 |    318.658030 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 858 |    785.496708 |    782.669905 | Gareth Monger                                                                                                                                                         |
| 859 |    774.497270 |    208.747813 | Tasman Dixon                                                                                                                                                          |
| 860 |      8.393652 |    666.586043 | Matt Crook                                                                                                                                                            |
| 861 |    920.520900 |    458.564986 | Zimices                                                                                                                                                               |
| 862 |    826.757672 |    559.496634 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 863 |    582.444274 |    236.978635 | Fernando Campos De Domenico                                                                                                                                           |
| 864 |    571.655217 |    259.589391 | Christian A. Masnaghetti                                                                                                                                              |
| 865 |    649.191302 |    738.398926 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 866 |    482.332320 |    140.592745 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 867 |    740.959062 |    601.238291 | Andy Wilson                                                                                                                                                           |
| 868 |    896.263697 |    441.296579 | Jaime Headden                                                                                                                                                         |
| 869 |    616.243046 |    498.271747 | Zimices                                                                                                                                                               |
| 870 |    650.295590 |    335.202516 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 871 |    679.788616 |     55.222806 | Matt Crook                                                                                                                                                            |
| 872 |    675.959731 |    756.430834 | Martin Kevil                                                                                                                                                          |
| 873 |    420.527095 |    376.182571 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                           |
| 874 |    336.730789 |    192.933362 | Margot Michaud                                                                                                                                                        |
| 875 |    426.057894 |    538.147964 | Cathy                                                                                                                                                                 |
| 876 |    424.231227 |    591.859023 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 877 |    497.593510 |     19.243346 | Jessica Anne Miller                                                                                                                                                   |
| 878 |     81.960022 |    387.951360 | NA                                                                                                                                                                    |
| 879 |   1014.197950 |    573.927699 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 880 |    768.376180 |    200.197241 | Zimices                                                                                                                                                               |
| 881 |    634.235745 |    311.708300 | Michael Scroggie                                                                                                                                                      |
| 882 |    481.013565 |    366.826121 | Mason McNair                                                                                                                                                          |
| 883 |    516.481494 |    789.522104 | Jagged Fang Designs                                                                                                                                                   |
| 884 |    635.014548 |    727.567710 | Jonathan Wells                                                                                                                                                        |
| 885 |   1006.013666 |    656.837602 | Zimices                                                                                                                                                               |
| 886 |    223.529264 |    743.319328 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 887 |    674.008223 |    300.403134 | NA                                                                                                                                                                    |
| 888 |   1006.271494 |    168.614411 | Scott Hartman                                                                                                                                                         |
| 889 |    565.814085 |    739.875672 | Jagged Fang Designs                                                                                                                                                   |
| 890 |    938.739794 |      2.336562 | Markus A. Grohme                                                                                                                                                      |
| 891 |    556.308747 |    351.631776 | Matt Crook                                                                                                                                                            |
| 892 |    469.702934 |    483.209911 | Steven Traver                                                                                                                                                         |
| 893 |    570.850271 |    249.902785 | Collin Gross                                                                                                                                                          |
| 894 |    196.287001 |    633.718663 | Margot Michaud                                                                                                                                                        |
| 895 |    536.314300 |    419.210889 | Gareth Monger                                                                                                                                                         |
| 896 |    714.334248 |    571.511205 | Felix Vaux                                                                                                                                                            |
| 897 |    657.185147 |    162.327836 | Sarah Werning                                                                                                                                                         |
| 898 |    798.722224 |    338.552996 | Chris huh                                                                                                                                                             |
| 899 |    943.765816 |    744.268112 | Steven Traver                                                                                                                                                         |
| 900 |    912.803074 |    685.129563 | Markus A. Grohme                                                                                                                                                      |
| 901 |    512.385462 |    543.866441 | Gareth Monger                                                                                                                                                         |
| 902 |     37.976155 |    119.918708 | Michael Scroggie                                                                                                                                                      |
| 903 |    252.390122 |    316.225812 | Markus A. Grohme                                                                                                                                                      |
| 904 |    518.366944 |    669.091645 | Zachary Quigley                                                                                                                                                       |
| 905 |    687.834721 |    517.627630 | Steven Traver                                                                                                                                                         |
| 906 |    165.699941 |    203.525541 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 907 |    794.629893 |    427.685225 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 908 |    816.040119 |    689.114434 | Gareth Monger                                                                                                                                                         |
| 909 |    463.425165 |    785.699313 | L. Shyamal                                                                                                                                                            |
| 910 |    287.927321 |     68.887416 | Scott Hartman                                                                                                                                                         |
| 911 |    783.754200 |    552.194698 | Margot Michaud                                                                                                                                                        |
| 912 |    591.929938 |    482.069548 | Chris huh                                                                                                                                                             |
| 913 |    988.173913 |    714.641193 | David Orr                                                                                                                                                             |
| 914 |    335.055529 |    364.322669 | Katie S. Collins                                                                                                                                                      |
| 915 |    783.069749 |    429.212220 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 916 |    539.752286 |    452.573666 | Dean Schnabel                                                                                                                                                         |

    #> Your tweet has been posted!
