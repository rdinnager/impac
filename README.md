
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

Matt Crook, Manabu Sakamoto, Sean McCann, Gabriela Palomo-Munoz, Mattia
Menchetti, Scott Hartman, Steven Traver, Margot Michaud, Chris huh, Jack
Mayer Wood, Jaime Headden, Nobu Tamura (modified by T. Michael Keesey),
Dmitry Bogdanov (vectorized by T. Michael Keesey), Steven Haddock
• Jellywatch.org, Melissa Broussard, Lukasiniho, Michele M Tobias
from an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Sarah
Werning, Carlos Cano-Barbacil, Alex Slavenko, Iain Reid, Tasman Dixon,
Zimices, Mariana Ruiz (vectorized by T. Michael Keesey), Gareth Monger,
T. Michael Keesey, James I. Kirkland, Luis Alcalá, Mark A. Loewen,
Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T.
Michael Keesey), Caleb M. Brown, Sarefo (vectorized by T. Michael
Keesey), SecretJellyMan - from Mason McNair, Ghedoghedo (vectorized by
T. Michael Keesey), Christoph Schomburg, Joanna Wolfe, Eduard Solà
(vectorized by T. Michael Keesey), Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Dean Schnabel, Andy Wilson, Steven Coombs, Tyler Greenfield, Collin
Gross, Beth Reinke, Lip Kee Yap (vectorized by T. Michael Keesey), Tracy
A. Heath, Jim Bendon (photography) and T. Michael Keesey
(vectorization), Jagged Fang Designs, C. Camilo Julián-Caballero,
Verisimilus, Noah Schlottman, photo by Carlos Sánchez-Ortiz, Noah
Schlottman, photo by Martin V. Sørensen, Kent Elson Sorgon, M Kolmann,
Ferran Sayol, Ignacio Contreras, Michael Scroggie, Jon Hill (Photo by
DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Mathew
Wedel, Francesco Veronesi (vectorized by T. Michael Keesey), Mali’o
Kodis, photograph by Bruno Vellutini, Ghedo and T. Michael Keesey,
Xvazquez (vectorized by William Gearty), Kamil S. Jaron, Nobu Tamura
(vectorized by T. Michael Keesey), Luis Cunha, Emily Willoughby, Maija
Karala, Ludwik Gasiorowski, Robbie N. Cada (vectorized by T. Michael
Keesey), Emma Hughes, Harold N Eyster, Chuanixn Yu, François Michonneau,
Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy, Derek
Bakken (photograph) and T. Michael Keesey (vectorization), Cesar Julian,
Darren Naish, Nemo, and T. Michael Keesey, Zimices / Julián Bayona, Yan
Wong, Sergio A. Muñoz-Gómez, Florian Pfaff, Kai R. Caspar, Alexander
Schmidt-Lebuhn, Tyler McCraney, L. Shyamal, T. Michael Keesey (after C.
De Muizon), Birgit Lang, Tauana J. Cunha, Xavier Giroux-Bougard,
Shyamal, Lani Mohan, Matt Martyniuk, Charles Doolittle Walcott
(vectorized by T. Michael Keesey), xgirouxb, Brad McFeeters (vectorized
by T. Michael Keesey), Chris Hay, Scott Reid, Roberto Díaz Sibaja, Becky
Barnes, Noah Schlottman, photo from Moorea Biocode, Frank Denota, Leon
P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin, Felix Vaux,
Matthew E. Clapham, Nobu Tamura, vectorized by Zimices, Juan Carlos
Jerí, Benjamint444, Pete Buchholz, Jordan Mallon (vectorized by T.
Michael Keesey), Renata F. Martins, Henry Lydecker, Matt Wilkins,
S.Martini, Michael P. Taylor, Mykle Hoban, Jake Warner, Mette Aumala, M
Hutchinson, Ingo Braasch, Manabu Bessho-Uehara, Nobu Tamura, modified by
Andrew A. Farke, Verdilak, CNZdenek, Mary Harrsch (modified by T.
Michael Keesey), Apokryltaros (vectorized by T. Michael Keesey), Didier
Descouens (vectorized by T. Michael Keesey), Agnello Picorelli, Stanton
F. Fink (vectorized by T. Michael Keesey), Frederick William Frohawk
(vectorized by T. Michael Keesey), Alexandre Vong, FunkMonk, Tony Ayling
(vectorized by T. Michael Keesey), Markus A. Grohme, Matt Celeskey,
Anthony Caravaggi, B. Duygu Özpolat, T. Michael Keesey (vectorization);
Yves Bousquet (photography), Chase Brownstein, I. Geoffroy Saint-Hilaire
(vectorized by T. Michael Keesey), kotik, Todd Marshall, vectorized by
Zimices, Renato de Carvalho Ferreira, Raven Amos, Kimberly Haddrell,
Kent Sorgon, T. Michael Keesey (from a mount by Allis Markham), Michelle
Site, Timothy Knepp (vectorized by T. Michael Keesey), T. Michael Keesey
(after James & al.), Noah Schlottman, photo by David J Patterson, Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Matt
Dempsey, Giant Blue Anteater (vectorized by T. Michael Keesey), Ellen
Edmonson (illustration) and Timothy J. Bartley (silhouette), Robbie N.
Cada (modified by T. Michael Keesey), Chris Jennings (Risiatto), Konsta
Happonen, from a CC-BY-NC image by pelhonen on iNaturalist, Nobu Tamura,
Dmitry Bogdanov, Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., Armin Reindl,
Bruno Maggia, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy
J. Bartley (silhouette), Tyler Greenfield and Scott Hartman, T. Michael
Keesey (after Mauricio Antón), Martien Brand (original photo), Renato
Santos (vector silhouette), Lukas Panzarin, Óscar San-Isidro (vectorized
by T. Michael Keesey), (unknown), E. R. Waite & H. M. Hale (vectorized
by T. Michael Keesey), Heinrich Harder (vectorized by T. Michael
Keesey), Smokeybjb, Amanda Katzer, Anilocra (vectorization by Yan Wong),
Andrew A. Farke, Michele M Tobias, Tambja (vectorized by T. Michael
Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    232.633377 |    504.313060 | Matt Crook                                                                                                                                                            |
|   2 |    176.880572 |     65.799824 | Matt Crook                                                                                                                                                            |
|   3 |    119.373437 |    386.570185 | Manabu Sakamoto                                                                                                                                                       |
|   4 |    582.112839 |    409.060276 | Sean McCann                                                                                                                                                           |
|   5 |    352.742095 |    323.210375 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   6 |     73.912234 |     65.304285 | Mattia Menchetti                                                                                                                                                      |
|   7 |    137.180303 |    649.161290 | Scott Hartman                                                                                                                                                         |
|   8 |    504.408387 |    318.902245 | Steven Traver                                                                                                                                                         |
|   9 |    688.732849 |    233.782218 | Margot Michaud                                                                                                                                                        |
|  10 |    859.388320 |    240.737213 | Margot Michaud                                                                                                                                                        |
|  11 |    300.621807 |    126.973739 | Steven Traver                                                                                                                                                         |
|  12 |    885.806881 |    480.292769 | Chris huh                                                                                                                                                             |
|  13 |    326.916664 |    700.276700 | Jack Mayer Wood                                                                                                                                                       |
|  14 |    490.949749 |    657.771003 | NA                                                                                                                                                                    |
|  15 |    796.964872 |    410.556861 | Jaime Headden                                                                                                                                                         |
|  16 |    582.380662 |    704.864904 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  17 |    912.276559 |    728.944612 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  18 |    524.390524 |    523.459880 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|  19 |    149.896599 |    722.588261 | Melissa Broussard                                                                                                                                                     |
|  20 |    623.109555 |     65.098497 | Steven Traver                                                                                                                                                         |
|  21 |    422.951488 |    240.927864 | Matt Crook                                                                                                                                                            |
|  22 |    937.980777 |    371.312492 | Lukasiniho                                                                                                                                                            |
|  23 |    391.675568 |    684.607260 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
|  24 |    227.481301 |    316.066948 | Matt Crook                                                                                                                                                            |
|  25 |    729.747701 |    691.626672 | Sarah Werning                                                                                                                                                         |
|  26 |    851.204587 |    570.284319 | Carlos Cano-Barbacil                                                                                                                                                  |
|  27 |    635.709377 |    596.787105 | Alex Slavenko                                                                                                                                                         |
|  28 |    463.886120 |     23.423189 | Iain Reid                                                                                                                                                             |
|  29 |    118.117189 |    186.732899 | Tasman Dixon                                                                                                                                                          |
|  30 |    249.108694 |    768.874712 | Zimices                                                                                                                                                               |
|  31 |    920.394898 |    284.046411 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|  32 |    858.049676 |     65.058149 | Jaime Headden                                                                                                                                                         |
|  33 |    508.942400 |    762.790692 | Chris huh                                                                                                                                                             |
|  34 |    832.727873 |    145.151183 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
|  35 |    961.948764 |    644.315836 | Melissa Broussard                                                                                                                                                     |
|  36 |    321.548077 |     40.430369 | Sarah Werning                                                                                                                                                         |
|  37 |    421.470362 |     71.156587 | Gareth Monger                                                                                                                                                         |
|  38 |    642.408944 |    642.880412 | Tasman Dixon                                                                                                                                                          |
|  39 |    256.887702 |    205.524763 | T. Michael Keesey                                                                                                                                                     |
|  40 |    430.293648 |    470.786258 | Melissa Broussard                                                                                                                                                     |
|  41 |    840.226562 |    451.670852 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|  42 |    597.441830 |    194.322293 | Tasman Dixon                                                                                                                                                          |
|  43 |    730.398202 |    479.881983 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
|  44 |    640.998820 |    314.095622 | Caleb M. Brown                                                                                                                                                        |
|  45 |     71.506028 |    730.076174 | Zimices                                                                                                                                                               |
|  46 |    242.026045 |    627.253548 | Margot Michaud                                                                                                                                                        |
|  47 |     65.324822 |    263.146070 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  48 |     79.453393 |    602.638539 | Steven Traver                                                                                                                                                         |
|  49 |    954.654637 |     82.928315 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
|  50 |    984.082573 |    533.075491 | SecretJellyMan - from Mason McNair                                                                                                                                    |
|  51 |    695.457770 |    129.204794 | Chris huh                                                                                                                                                             |
|  52 |    458.265848 |    146.036418 | Zimices                                                                                                                                                               |
|  53 |    744.572109 |    358.825230 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  54 |    191.227330 |    126.558911 | T. Michael Keesey                                                                                                                                                     |
|  55 |    869.745921 |    653.907698 | Zimices                                                                                                                                                               |
|  56 |    194.243831 |    589.863870 | Carlos Cano-Barbacil                                                                                                                                                  |
|  57 |    254.811248 |    427.083802 | Zimices                                                                                                                                                               |
|  58 |    705.647575 |    739.711453 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  59 |    838.237930 |    320.317237 | Chris huh                                                                                                                                                             |
|  60 |    963.037926 |    163.937884 | Tasman Dixon                                                                                                                                                          |
|  61 |    376.098638 |    393.294314 | Christoph Schomburg                                                                                                                                                   |
|  62 |    829.985389 |    695.268294 | Steven Traver                                                                                                                                                         |
|  63 |    674.041486 |    536.607021 | Joanna Wolfe                                                                                                                                                          |
|  64 |    294.083198 |     73.634708 | NA                                                                                                                                                                    |
|  65 |    475.957508 |    249.775678 | Matt Crook                                                                                                                                                            |
|  66 |    728.768628 |    780.823982 | Chris huh                                                                                                                                                             |
|  67 |     88.640168 |     16.281966 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
|  68 |    363.670594 |    229.858578 | Matt Crook                                                                                                                                                            |
|  69 |    153.056251 |    313.559920 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  70 |    513.473350 |    584.473469 | Dean Schnabel                                                                                                                                                         |
|  71 |    177.912657 |    369.529357 | Andy Wilson                                                                                                                                                           |
|  72 |    285.965707 |    566.744521 | Chris huh                                                                                                                                                             |
|  73 |    751.192826 |    627.346927 | Zimices                                                                                                                                                               |
|  74 |    896.154249 |     15.528788 | Steven Coombs                                                                                                                                                         |
|  75 |    998.121321 |    227.684036 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
|  76 |    104.053894 |    564.337990 | Tyler Greenfield                                                                                                                                                      |
|  77 |    443.257515 |    744.563712 | Scott Hartman                                                                                                                                                         |
|  78 |    600.129039 |    261.842711 | Collin Gross                                                                                                                                                          |
|  79 |    851.878111 |    364.895493 | Beth Reinke                                                                                                                                                           |
|  80 |    373.360610 |    765.618782 | NA                                                                                                                                                                    |
|  81 |    314.228848 |    742.550032 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
|  82 |     35.216905 |    369.944581 | T. Michael Keesey                                                                                                                                                     |
|  83 |    966.059599 |    770.855265 | Zimices                                                                                                                                                               |
|  84 |    201.822258 |    702.534504 | Tracy A. Heath                                                                                                                                                        |
|  85 |    102.369058 |    327.699869 | Margot Michaud                                                                                                                                                        |
|  86 |     97.200367 |    137.369036 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                        |
|  87 |    547.442966 |    140.922138 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  88 |    857.210094 |    758.387492 | Jagged Fang Designs                                                                                                                                                   |
|  89 |    499.538723 |    400.174571 | C. Camilo Julián-Caballero                                                                                                                                            |
|  90 |    588.290696 |    491.875889 | Verisimilus                                                                                                                                                           |
|  91 |     61.856507 |    674.626118 | Zimices                                                                                                                                                               |
|  92 |    126.248534 |    450.282664 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
|  93 |    128.389335 |    210.090335 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
|  94 |    942.986476 |    427.101435 | Kent Elson Sorgon                                                                                                                                                     |
|  95 |    507.314608 |     60.167952 | Matt Crook                                                                                                                                                            |
|  96 |    869.231842 |    407.725175 | M Kolmann                                                                                                                                                             |
|  97 |    188.991691 |    242.438930 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  98 |    744.106711 |     22.255292 | Matt Crook                                                                                                                                                            |
|  99 |    334.460044 |    448.704950 | Kent Elson Sorgon                                                                                                                                                     |
| 100 |     37.647886 |    126.358249 | Zimices                                                                                                                                                               |
| 101 |    750.205976 |    158.130927 | Ferran Sayol                                                                                                                                                          |
| 102 |    788.206705 |    445.541019 | Sarah Werning                                                                                                                                                         |
| 103 |    559.832791 |    474.335483 | Ignacio Contreras                                                                                                                                                     |
| 104 |    805.652845 |    678.852873 | Michael Scroggie                                                                                                                                                      |
| 105 |    793.150999 |     46.528739 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 106 |    596.128952 |    523.005543 | Melissa Broussard                                                                                                                                                     |
| 107 |   1006.785573 |    278.437049 | Tyler Greenfield                                                                                                                                                      |
| 108 |    716.133028 |    401.715312 | Mathew Wedel                                                                                                                                                          |
| 109 |     55.295781 |    542.136909 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 110 |    518.625052 |    791.382635 | Tasman Dixon                                                                                                                                                          |
| 111 |    960.190543 |    214.764414 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 112 |    336.886102 |    213.791223 | Steven Traver                                                                                                                                                         |
| 113 |    329.119879 |    767.845306 | Caleb M. Brown                                                                                                                                                        |
| 114 |    548.232560 |    346.616485 | Carlos Cano-Barbacil                                                                                                                                                  |
| 115 |    759.693552 |    500.570782 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 116 |    770.435600 |    290.744856 | Joanna Wolfe                                                                                                                                                          |
| 117 |    372.937658 |    490.769327 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 118 |    754.137724 |    325.541514 | Collin Gross                                                                                                                                                          |
| 119 |    250.687600 |    685.519003 | Zimices                                                                                                                                                               |
| 120 |    991.214956 |    704.242342 | Margot Michaud                                                                                                                                                        |
| 121 |    811.302273 |    502.967832 | Gareth Monger                                                                                                                                                         |
| 122 |    646.965416 |    198.021568 | Margot Michaud                                                                                                                                                        |
| 123 |    922.899521 |    242.415195 | Steven Traver                                                                                                                                                         |
| 124 |    889.588961 |    115.098546 | Steven Traver                                                                                                                                                         |
| 125 |    447.865278 |    612.154894 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 126 |    567.698025 |    652.877038 | Ferran Sayol                                                                                                                                                          |
| 127 |     40.156372 |    203.809882 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 128 |    968.375747 |    466.389886 | Gareth Monger                                                                                                                                                         |
| 129 |    451.830957 |    329.371287 | Matt Crook                                                                                                                                                            |
| 130 |    606.723974 |    773.792351 | Kamil S. Jaron                                                                                                                                                        |
| 131 |    184.627594 |    787.969164 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 132 |    374.715253 |    139.042326 | Luis Cunha                                                                                                                                                            |
| 133 |    585.829959 |      9.203422 | Emily Willoughby                                                                                                                                                      |
| 134 |    518.798090 |    461.671030 | Chris huh                                                                                                                                                             |
| 135 |    357.397600 |    177.074716 | Maija Karala                                                                                                                                                          |
| 136 |    593.508858 |    117.196817 | Matt Crook                                                                                                                                                            |
| 137 |    545.640933 |     61.984954 | Ludwik Gasiorowski                                                                                                                                                    |
| 138 |    662.573140 |    346.621455 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 139 |    382.593501 |    157.398438 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 140 |    315.947068 |    582.389952 | Emma Hughes                                                                                                                                                           |
| 141 |    951.010496 |    320.876304 | Jack Mayer Wood                                                                                                                                                       |
| 142 |    774.609188 |    259.149491 | Harold N Eyster                                                                                                                                                       |
| 143 |    355.325589 |    694.415118 | Tasman Dixon                                                                                                                                                          |
| 144 |     88.465827 |    436.378607 | Jagged Fang Designs                                                                                                                                                   |
| 145 |     12.293265 |    171.370340 | NA                                                                                                                                                                    |
| 146 |    671.096921 |    282.154472 | Jagged Fang Designs                                                                                                                                                   |
| 147 |    579.868911 |    621.364221 | Chuanixn Yu                                                                                                                                                           |
| 148 |    137.440086 |    199.837554 | François Michonneau                                                                                                                                                   |
| 149 |    916.784275 |    511.350823 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 150 |     33.466149 |    532.975141 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 151 |    951.563965 |    609.780414 | Margot Michaud                                                                                                                                                        |
| 152 |    821.586698 |    387.220656 | Zimices                                                                                                                                                               |
| 153 |   1009.145594 |     79.459520 | Tyler Greenfield                                                                                                                                                      |
| 154 |    200.963488 |    256.050125 | Matt Crook                                                                                                                                                            |
| 155 |    247.166605 |     17.436519 | Cesar Julian                                                                                                                                                          |
| 156 |    648.794523 |    764.482865 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                             |
| 157 |    557.338643 |    316.990252 | Carlos Cano-Barbacil                                                                                                                                                  |
| 158 |    747.648869 |     90.582333 | Andy Wilson                                                                                                                                                           |
| 159 |     52.374901 |    337.328444 | Zimices / Julián Bayona                                                                                                                                               |
| 160 |    788.725961 |    507.177744 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 161 |    719.889395 |    308.163875 | Tasman Dixon                                                                                                                                                          |
| 162 |    565.878202 |    373.077251 | NA                                                                                                                                                                    |
| 163 |    170.069909 |    165.043263 | Yan Wong                                                                                                                                                              |
| 164 |    357.264538 |    590.143648 | Zimices                                                                                                                                                               |
| 165 |    454.537081 |    561.116883 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 166 |   1006.768031 |    676.083310 | Florian Pfaff                                                                                                                                                         |
| 167 |    995.985154 |    740.227130 | Kai R. Caspar                                                                                                                                                         |
| 168 |    585.376239 |    290.384586 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 169 |    286.295480 |    531.264310 | Zimices                                                                                                                                                               |
| 170 |    345.774329 |    628.549910 | Gareth Monger                                                                                                                                                         |
| 171 |    670.653450 |    171.887913 | Harold N Eyster                                                                                                                                                       |
| 172 |    821.649948 |    791.310002 | Tyler McCraney                                                                                                                                                        |
| 173 |    798.656519 |    377.401243 | Matt Crook                                                                                                                                                            |
| 174 |    791.130420 |     83.074234 | Gareth Monger                                                                                                                                                         |
| 175 |    755.889809 |    316.528523 | Jagged Fang Designs                                                                                                                                                   |
| 176 |    307.299511 |    387.372547 | NA                                                                                                                                                                    |
| 177 |    763.050662 |    534.630486 | Margot Michaud                                                                                                                                                        |
| 178 |    686.074373 |    571.471179 | Scott Hartman                                                                                                                                                         |
| 179 |    169.961559 |    621.762308 | Gareth Monger                                                                                                                                                         |
| 180 |    588.321314 |    276.640151 | NA                                                                                                                                                                    |
| 181 |    539.282457 |    598.835560 | L. Shyamal                                                                                                                                                            |
| 182 |     48.639073 |    306.739444 | Gareth Monger                                                                                                                                                         |
| 183 |    300.224841 |    766.677809 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 184 |    108.418663 |    226.784301 | Birgit Lang                                                                                                                                                           |
| 185 |    730.626262 |    706.526878 | Jaime Headden                                                                                                                                                         |
| 186 |    287.083026 |    360.848619 | Matt Crook                                                                                                                                                            |
| 187 |    592.579616 |    439.892348 | Tauana J. Cunha                                                                                                                                                       |
| 188 |    704.615724 |    714.264925 | Xavier Giroux-Bougard                                                                                                                                                 |
| 189 |    246.510608 |    719.691389 | Gareth Monger                                                                                                                                                         |
| 190 |    799.143795 |    304.536360 | Shyamal                                                                                                                                                               |
| 191 |    444.575173 |    386.994226 | T. Michael Keesey                                                                                                                                                     |
| 192 |    464.325081 |    495.300973 | Matt Crook                                                                                                                                                            |
| 193 |    173.489352 |    457.197497 | NA                                                                                                                                                                    |
| 194 |    655.722735 |    695.795509 | Lani Mohan                                                                                                                                                            |
| 195 |    230.768642 |    669.551763 | Michael Scroggie                                                                                                                                                      |
| 196 |    709.758439 |    613.730419 | Andy Wilson                                                                                                                                                           |
| 197 |    774.352572 |    211.017610 | Matt Martyniuk                                                                                                                                                        |
| 198 |    901.521917 |    689.033079 | Ferran Sayol                                                                                                                                                          |
| 199 |    391.777550 |     20.047257 | Scott Hartman                                                                                                                                                         |
| 200 |    535.320034 |    237.830078 | T. Michael Keesey                                                                                                                                                     |
| 201 |    367.846367 |    716.417766 | Tracy A. Heath                                                                                                                                                        |
| 202 |    277.577082 |     11.564153 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 203 |    854.075444 |     27.159855 | Scott Hartman                                                                                                                                                         |
| 204 |    672.652448 |    397.085110 | NA                                                                                                                                                                    |
| 205 |    931.280119 |    208.665677 | Zimices                                                                                                                                                               |
| 206 |     23.999960 |    482.524868 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 207 |    755.910294 |     55.120790 | NA                                                                                                                                                                    |
| 208 |    508.467101 |    736.094011 | Scott Hartman                                                                                                                                                         |
| 209 |    118.477304 |    784.159390 | T. Michael Keesey                                                                                                                                                     |
| 210 |    170.999144 |    305.212119 | xgirouxb                                                                                                                                                              |
| 211 |    239.968986 |    250.292009 | Zimices                                                                                                                                                               |
| 212 |    732.248799 |    577.505699 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 213 |    825.613933 |     75.736129 | Matt Crook                                                                                                                                                            |
| 214 |    814.263143 |    728.632923 | Zimices                                                                                                                                                               |
| 215 |    725.068667 |    382.802209 | Jaime Headden                                                                                                                                                         |
| 216 |    552.845091 |    782.124337 | NA                                                                                                                                                                    |
| 217 |    432.613672 |    558.257737 | Tracy A. Heath                                                                                                                                                        |
| 218 |      8.722727 |    438.981568 | Gareth Monger                                                                                                                                                         |
| 219 |     60.969680 |    645.373292 | xgirouxb                                                                                                                                                              |
| 220 |    774.458789 |    742.297566 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 221 |    988.232118 |    447.496597 | Zimices                                                                                                                                                               |
| 222 |    914.531793 |    452.381100 | Chris Hay                                                                                                                                                             |
| 223 |    692.370316 |     26.271249 | L. Shyamal                                                                                                                                                            |
| 224 |    946.089356 |    556.404008 | Scott Reid                                                                                                                                                            |
| 225 |    901.919263 |    615.466528 | Matt Crook                                                                                                                                                            |
| 226 |    581.618027 |    337.323722 | Roberto Díaz Sibaja                                                                                                                                                   |
| 227 |    180.668311 |    216.457346 | Andy Wilson                                                                                                                                                           |
| 228 |    222.497263 |    153.863808 | Ludwik Gasiorowski                                                                                                                                                    |
| 229 |    600.465977 |    567.153027 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 230 |    289.957372 |    252.711928 | Becky Barnes                                                                                                                                                          |
| 231 |     19.283784 |    669.244043 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 232 |    954.007266 |    446.440618 | Roberto Díaz Sibaja                                                                                                                                                   |
| 233 |    543.485043 |    411.747544 | Margot Michaud                                                                                                                                                        |
| 234 |    692.139197 |    432.619406 | Zimices                                                                                                                                                               |
| 235 |    751.225705 |    546.958951 | Ferran Sayol                                                                                                                                                          |
| 236 |    693.343965 |    630.786514 | Frank Denota                                                                                                                                                          |
| 237 |    520.069961 |    562.555512 | Gareth Monger                                                                                                                                                         |
| 238 |    755.260210 |    454.214485 | NA                                                                                                                                                                    |
| 239 |    753.774865 |    717.250980 | Sarah Werning                                                                                                                                                         |
| 240 |    808.373290 |    637.727841 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 241 |    316.248907 |    632.941503 | Scott Hartman                                                                                                                                                         |
| 242 |    478.412311 |    101.760356 | Melissa Broussard                                                                                                                                                     |
| 243 |    799.771054 |    249.386293 | Felix Vaux                                                                                                                                                            |
| 244 |    823.122172 |    781.465519 | Scott Hartman                                                                                                                                                         |
| 245 |    137.427492 |    150.890370 | Matthew E. Clapham                                                                                                                                                    |
| 246 |    168.738174 |    232.095201 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 247 |     38.030221 |    149.106091 | Juan Carlos Jerí                                                                                                                                                      |
| 248 |    501.475787 |    250.185649 | Benjamint444                                                                                                                                                          |
| 249 |    836.356074 |    738.740502 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 250 |    989.669717 |    778.061680 | NA                                                                                                                                                                    |
| 251 |    167.800969 |     20.193932 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 252 |     34.082524 |    411.742995 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 253 |     22.115886 |    296.830624 | Gareth Monger                                                                                                                                                         |
| 254 |    422.439584 |    109.871901 | Christoph Schomburg                                                                                                                                                   |
| 255 |    438.509519 |    690.810573 | NA                                                                                                                                                                    |
| 256 |    609.444216 |    470.933317 | Zimices                                                                                                                                                               |
| 257 |    769.524136 |    111.538377 | Pete Buchholz                                                                                                                                                         |
| 258 |    645.460749 |    502.471411 | Steven Traver                                                                                                                                                         |
| 259 |    958.335417 |    792.220910 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 260 |    840.668309 |    285.723704 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 261 |    982.277411 |    299.607485 | T. Michael Keesey                                                                                                                                                     |
| 262 |    786.258672 |    764.820640 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 263 |    512.501321 |     89.786224 | Margot Michaud                                                                                                                                                        |
| 264 |    325.418586 |    181.278820 | Renata F. Martins                                                                                                                                                     |
| 265 |    832.205612 |     17.424692 | Jack Mayer Wood                                                                                                                                                       |
| 266 |     69.309784 |    784.779650 | Henry Lydecker                                                                                                                                                        |
| 267 |    748.323840 |    232.811483 | Zimices                                                                                                                                                               |
| 268 |    201.810447 |    473.900599 | Steven Traver                                                                                                                                                         |
| 269 |    892.836237 |    170.629431 | Margot Michaud                                                                                                                                                        |
| 270 |   1009.712657 |     43.394940 | Matt Wilkins                                                                                                                                                          |
| 271 |    982.110378 |    144.345233 | S.Martini                                                                                                                                                             |
| 272 |    520.638288 |    448.308292 | Scott Hartman                                                                                                                                                         |
| 273 |    341.533068 |    433.800516 | Michael P. Taylor                                                                                                                                                     |
| 274 |     20.925552 |    792.221786 | Collin Gross                                                                                                                                                          |
| 275 |    557.247202 |    332.521484 | Mykle Hoban                                                                                                                                                           |
| 276 |    649.724765 |    100.777003 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 277 |    109.017774 |    746.464163 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 278 |    294.179801 |    392.798927 | Scott Hartman                                                                                                                                                         |
| 279 |     83.873709 |    528.124815 | Matt Crook                                                                                                                                                            |
| 280 |    761.726792 |    273.906167 | Collin Gross                                                                                                                                                          |
| 281 |    420.138057 |    150.702660 | Jake Warner                                                                                                                                                           |
| 282 |    559.478551 |    391.377715 | Mette Aumala                                                                                                                                                          |
| 283 |    228.966025 |    383.124556 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 284 |    685.650558 |    584.191653 | Cesar Julian                                                                                                                                                          |
| 285 |     20.766159 |    701.329067 | M Hutchinson                                                                                                                                                          |
| 286 |    186.318716 |    732.798322 | Ingo Braasch                                                                                                                                                          |
| 287 |    375.021165 |    791.019439 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 288 |    285.044602 |    586.866004 | Manabu Bessho-Uehara                                                                                                                                                  |
| 289 |    780.382471 |    692.715478 | Steven Traver                                                                                                                                                         |
| 290 |    935.820210 |    227.791092 | Birgit Lang                                                                                                                                                           |
| 291 |    300.191071 |    647.739890 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 292 |    427.395076 |    335.642555 | Jaime Headden                                                                                                                                                         |
| 293 |    729.081878 |     55.577679 | T. Michael Keesey                                                                                                                                                     |
| 294 |    135.440114 |    260.679780 | Matt Crook                                                                                                                                                            |
| 295 |    952.744875 |    252.735962 | Tyler Greenfield                                                                                                                                                      |
| 296 |     56.211334 |    523.429043 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 297 |     13.881840 |    631.490496 | Verdilak                                                                                                                                                              |
| 298 |    323.822549 |     12.550615 | Jagged Fang Designs                                                                                                                                                   |
| 299 |    439.535816 |    719.799933 | C. Camilo Julián-Caballero                                                                                                                                            |
| 300 |    193.168890 |    621.005677 | Emily Willoughby                                                                                                                                                      |
| 301 |    652.679696 |    583.536057 | Chris huh                                                                                                                                                             |
| 302 |    886.744431 |     43.546978 | M Kolmann                                                                                                                                                             |
| 303 |    552.095983 |     35.261708 | Zimices                                                                                                                                                               |
| 304 |    942.597937 |    475.455746 | CNZdenek                                                                                                                                                              |
| 305 |     54.305647 |    171.388787 | Zimices                                                                                                                                                               |
| 306 |    622.114156 |    217.252922 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 307 |    972.778788 |    713.719565 | Dean Schnabel                                                                                                                                                         |
| 308 |    560.581594 |    504.432088 | Scott Hartman                                                                                                                                                         |
| 309 |    999.908026 |    415.606544 | Matt Crook                                                                                                                                                            |
| 310 |     25.542014 |    557.942190 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 311 |    181.988319 |    328.867588 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 312 |    599.900810 |    577.238125 | Agnello Picorelli                                                                                                                                                     |
| 313 |    722.049035 |    649.407132 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 314 |    978.761094 |    192.820524 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 315 |    692.712678 |    485.554346 | Chris huh                                                                                                                                                             |
| 316 |    266.269206 |     84.104112 | Gareth Monger                                                                                                                                                         |
| 317 |    414.155839 |     32.952700 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 318 |    557.659183 |     79.419264 | Xavier Giroux-Bougard                                                                                                                                                 |
| 319 |    143.644056 |    309.448100 | Gareth Monger                                                                                                                                                         |
| 320 |     15.558516 |    550.938435 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 321 |    474.939305 |     52.662289 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 322 |    751.943690 |    246.698083 | Sean McCann                                                                                                                                                           |
| 323 |    446.366712 |    309.709336 | Joanna Wolfe                                                                                                                                                          |
| 324 |    625.983700 |    166.476893 | Alexandre Vong                                                                                                                                                        |
| 325 |   1000.943616 |    112.258326 | FunkMonk                                                                                                                                                              |
| 326 |    709.596261 |     14.165623 | NA                                                                                                                                                                    |
| 327 |    923.480923 |    626.062660 | Chris huh                                                                                                                                                             |
| 328 |    132.881772 |    455.355236 | Steven Coombs                                                                                                                                                         |
| 329 |    712.630824 |    594.912382 | Birgit Lang                                                                                                                                                           |
| 330 |    884.252317 |    791.156158 | Tasman Dixon                                                                                                                                                          |
| 331 |    385.654839 |    698.268057 | Gareth Monger                                                                                                                                                         |
| 332 |    745.302541 |    412.558768 | Chris huh                                                                                                                                                             |
| 333 |    613.671530 |    728.451353 | Matt Crook                                                                                                                                                            |
| 334 |    629.623873 |    685.266693 | Margot Michaud                                                                                                                                                        |
| 335 |    980.292706 |     18.125226 | Mathew Wedel                                                                                                                                                          |
| 336 |    701.410322 |    153.966594 | Ignacio Contreras                                                                                                                                                     |
| 337 |    431.682907 |    783.627968 | Matt Crook                                                                                                                                                            |
| 338 |    844.813948 |    628.121870 | Margot Michaud                                                                                                                                                        |
| 339 |    939.973053 |    195.849672 | Sarah Werning                                                                                                                                                         |
| 340 |    103.771822 |    684.417605 | T. Michael Keesey                                                                                                                                                     |
| 341 |    478.569409 |    722.137010 | Ferran Sayol                                                                                                                                                          |
| 342 |    395.849733 |    420.106770 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 343 |    211.771573 |    353.336667 | Markus A. Grohme                                                                                                                                                      |
| 344 |    198.545262 |    657.992643 | Markus A. Grohme                                                                                                                                                      |
| 345 |    561.472378 |    243.500269 | NA                                                                                                                                                                    |
| 346 |    225.423745 |     53.438870 | Kamil S. Jaron                                                                                                                                                        |
| 347 |     74.765681 |    464.350660 | NA                                                                                                                                                                    |
| 348 |    581.694525 |    461.452062 | Chris huh                                                                                                                                                             |
| 349 |     93.730284 |    768.993033 | Matt Crook                                                                                                                                                            |
| 350 |    431.095907 |    422.635701 | Markus A. Grohme                                                                                                                                                      |
| 351 |    905.301183 |    756.647603 | Carlos Cano-Barbacil                                                                                                                                                  |
| 352 |    328.324518 |    614.574282 | Margot Michaud                                                                                                                                                        |
| 353 |    597.606626 |    154.887085 | Ferran Sayol                                                                                                                                                          |
| 354 |    102.240579 |    543.958002 | Carlos Cano-Barbacil                                                                                                                                                  |
| 355 |    450.463535 |    353.552888 | Christoph Schomburg                                                                                                                                                   |
| 356 |    844.888725 |    256.005116 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 357 |    166.082610 |    200.667544 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 358 |    691.815135 |     84.430020 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 359 |    589.237256 |    236.177338 | Matt Celeskey                                                                                                                                                         |
| 360 |    296.443416 |    326.054937 | Beth Reinke                                                                                                                                                           |
| 361 |    907.565745 |    405.109117 | Anthony Caravaggi                                                                                                                                                     |
| 362 |   1014.551878 |    375.846714 | NA                                                                                                                                                                    |
| 363 |    198.550904 |     71.499220 | B. Duygu Özpolat                                                                                                                                                      |
| 364 |    657.457281 |    666.841060 | Matt Crook                                                                                                                                                            |
| 365 |    443.747371 |    534.655452 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 366 |    370.360737 |      7.351671 | Zimices                                                                                                                                                               |
| 367 |    528.416231 |    182.742785 | Chase Brownstein                                                                                                                                                      |
| 368 |    695.661713 |     96.014889 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 369 |    346.068044 |    286.693627 | kotik                                                                                                                                                                 |
| 370 |    494.555052 |    596.372715 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 371 |    155.898846 |    617.303510 | Ferran Sayol                                                                                                                                                          |
| 372 |     22.410978 |    414.872436 | Renato de Carvalho Ferreira                                                                                                                                           |
| 373 |    240.591622 |    568.725249 | Jagged Fang Designs                                                                                                                                                   |
| 374 |    963.839843 |    601.141344 | Scott Hartman                                                                                                                                                         |
| 375 |    902.934325 |    254.987235 | Chris huh                                                                                                                                                             |
| 376 |    392.601568 |    121.246321 | Caleb M. Brown                                                                                                                                                        |
| 377 |    967.351279 |    583.827195 | Raven Amos                                                                                                                                                            |
| 378 |    446.939718 |    661.652544 | Scott Hartman                                                                                                                                                         |
| 379 |    736.545985 |    106.168342 | Kimberly Haddrell                                                                                                                                                     |
| 380 |    326.836465 |    413.654091 | Kent Sorgon                                                                                                                                                           |
| 381 |     67.804246 |    283.138853 | Steven Traver                                                                                                                                                         |
| 382 |    253.435353 |     43.670432 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 383 |    582.569132 |    403.261318 | Kent Elson Sorgon                                                                                                                                                     |
| 384 |    137.701913 |    175.968795 | Michelle Site                                                                                                                                                         |
| 385 |   1001.154551 |    142.672895 | NA                                                                                                                                                                    |
| 386 |    670.794333 |    359.597725 | Steven Traver                                                                                                                                                         |
| 387 |    110.910557 |    308.977786 | Beth Reinke                                                                                                                                                           |
| 388 |     17.765744 |    105.410775 | Emily Willoughby                                                                                                                                                      |
| 389 |    344.111411 |    793.232632 | Margot Michaud                                                                                                                                                        |
| 390 |    502.078664 |    187.128604 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 391 |    279.501159 |    384.401942 | Tasman Dixon                                                                                                                                                          |
| 392 |    821.832036 |    348.950530 | Margot Michaud                                                                                                                                                        |
| 393 |    291.957917 |    447.517179 | Margot Michaud                                                                                                                                                        |
| 394 |    504.873652 |    779.455371 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 395 |    611.869565 |    665.916735 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 396 |    554.194232 |    453.340148 | xgirouxb                                                                                                                                                              |
| 397 |    895.138487 |    130.353405 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 398 |    294.712276 |    665.998771 | Zimices                                                                                                                                                               |
| 399 |    598.775789 |    557.201280 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 400 |    666.951224 |    155.070285 | Matt Dempsey                                                                                                                                                          |
| 401 |    190.532051 |    677.070880 | T. Michael Keesey                                                                                                                                                     |
| 402 |    559.220320 |    443.350923 | C. Camilo Julián-Caballero                                                                                                                                            |
| 403 |    200.594064 |    794.833641 | Markus A. Grohme                                                                                                                                                      |
| 404 |    151.704383 |     49.498364 | Zimices                                                                                                                                                               |
| 405 |     18.476930 |    511.406433 | Emily Willoughby                                                                                                                                                      |
| 406 |    659.265453 |    219.811029 | Jack Mayer Wood                                                                                                                                                       |
| 407 |    546.170099 |    376.740921 | Ferran Sayol                                                                                                                                                          |
| 408 |    943.161644 |     17.049398 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 409 |    132.239872 |    664.563146 | Dean Schnabel                                                                                                                                                         |
| 410 |    368.177116 |    761.759894 | Zimices                                                                                                                                                               |
| 411 |    518.284666 |    524.133646 | NA                                                                                                                                                                    |
| 412 |    756.265921 |    221.693444 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 413 |    333.846817 |    203.265192 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 414 |    677.230281 |    500.475697 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 415 |    399.464115 |    507.523578 | Ferran Sayol                                                                                                                                                          |
| 416 |    223.533631 |    743.321390 | Ferran Sayol                                                                                                                                                          |
| 417 |    823.366384 |    485.887570 | Steven Traver                                                                                                                                                         |
| 418 |    467.369124 |    452.261027 | Chris huh                                                                                                                                                             |
| 419 |    999.089365 |    338.704564 | Birgit Lang                                                                                                                                                           |
| 420 |    235.884627 |    456.873051 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 421 |    515.966639 |    102.976528 | NA                                                                                                                                                                    |
| 422 |    293.915783 |    550.054106 | Pete Buchholz                                                                                                                                                         |
| 423 |    580.787318 |    359.956571 | Ferran Sayol                                                                                                                                                          |
| 424 |    615.697892 |    134.067124 | Gareth Monger                                                                                                                                                         |
| 425 |    487.919871 |    429.223620 | Jagged Fang Designs                                                                                                                                                   |
| 426 |    423.124305 |    406.228705 | Chris Jennings (Risiatto)                                                                                                                                             |
| 427 |    538.222404 |    214.893365 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 428 |    120.667356 |    539.606731 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
| 429 |    114.836762 |    340.710581 | Jagged Fang Designs                                                                                                                                                   |
| 430 |    290.301950 |    792.653267 | Margot Michaud                                                                                                                                                        |
| 431 |    244.972980 |    394.961587 | Nobu Tamura                                                                                                                                                           |
| 432 |    913.125184 |    308.470510 | Dmitry Bogdanov                                                                                                                                                       |
| 433 |    587.836738 |    756.680277 | Scott Hartman                                                                                                                                                         |
| 434 |    225.916581 |    263.115932 | NA                                                                                                                                                                    |
| 435 |    606.560081 |    794.799501 | Scott Hartman                                                                                                                                                         |
| 436 |    504.064510 |    474.171474 | Markus A. Grohme                                                                                                                                                      |
| 437 |    647.354862 |    512.350014 | Collin Gross                                                                                                                                                          |
| 438 |     15.598236 |    608.035205 | Scott Hartman                                                                                                                                                         |
| 439 |    963.191248 |    401.454284 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 440 |    669.637650 |     36.528040 | Matt Crook                                                                                                                                                            |
| 441 |    773.002426 |    379.564245 | Shyamal                                                                                                                                                               |
| 442 |    752.299032 |    727.771898 | T. Michael Keesey                                                                                                                                                     |
| 443 |    800.714383 |    666.356195 | Margot Michaud                                                                                                                                                        |
| 444 |    589.226983 |    586.096546 | Frank Denota                                                                                                                                                          |
| 445 |    384.438365 |    440.954215 | Zimices                                                                                                                                                               |
| 446 |   1009.472464 |    635.195373 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 447 |    708.976749 |    337.611933 | Armin Reindl                                                                                                                                                          |
| 448 |    201.290045 |    335.305875 | T. Michael Keesey                                                                                                                                                     |
| 449 |    124.218533 |    726.631947 | Bruno Maggia                                                                                                                                                          |
| 450 |    422.455546 |    574.382697 | Ignacio Contreras                                                                                                                                                     |
| 451 |    593.035865 |    300.251020 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 452 |     38.240244 |    649.244037 | Matt Dempsey                                                                                                                                                          |
| 453 |    701.389249 |    387.800522 | Cesar Julian                                                                                                                                                          |
| 454 |    330.386196 |    226.738069 | Matt Crook                                                                                                                                                            |
| 455 |    885.309047 |    639.990623 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 456 |    684.717305 |    216.355654 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 457 |    272.227176 |    741.141790 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
| 458 |     29.188095 |    175.768067 | Armin Reindl                                                                                                                                                          |
| 459 |    659.016216 |    379.266561 | NA                                                                                                                                                                    |
| 460 |     35.139719 |    448.642020 | Armin Reindl                                                                                                                                                          |
| 461 |     97.869958 |    304.627669 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 462 |    197.611662 |     84.544221 | Jagged Fang Designs                                                                                                                                                   |
| 463 |    940.989161 |    303.662065 | Margot Michaud                                                                                                                                                        |
| 464 |     54.440013 |    136.645220 | T. Michael Keesey                                                                                                                                                     |
| 465 |    534.922554 |    561.881269 | T. Michael Keesey                                                                                                                                                     |
| 466 |    194.704260 |    500.416871 | Lukas Panzarin                                                                                                                                                        |
| 467 |    338.935991 |    647.428362 | Zimices                                                                                                                                                               |
| 468 |    931.251874 |    769.940044 | T. Michael Keesey                                                                                                                                                     |
| 469 |    343.877175 |    665.464042 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 470 |    363.868944 |     55.870848 | Markus A. Grohme                                                                                                                                                      |
| 471 |    755.877540 |    118.756412 | Mathew Wedel                                                                                                                                                          |
| 472 |    173.752729 |    476.372873 | (unknown)                                                                                                                                                             |
| 473 |    869.000053 |    774.823179 | Gareth Monger                                                                                                                                                         |
| 474 |    908.242568 |    100.820811 | Gareth Monger                                                                                                                                                         |
| 475 |    480.037889 |    180.906399 | Jagged Fang Designs                                                                                                                                                   |
| 476 |    422.367195 |    165.274409 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 477 |    343.934235 |    470.305264 | Chris huh                                                                                                                                                             |
| 478 |     80.153562 |    411.005757 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 479 |    489.991829 |    117.125813 | Smokeybjb                                                                                                                                                             |
| 480 |    357.671447 |    409.997513 | Scott Hartman                                                                                                                                                         |
| 481 |    223.535262 |    123.948075 | Scott Hartman                                                                                                                                                         |
| 482 |     56.496959 |    218.983405 | Gareth Monger                                                                                                                                                         |
| 483 |    917.186752 |     40.559151 | Gareth Monger                                                                                                                                                         |
| 484 |    853.889124 |     39.935280 | Markus A. Grohme                                                                                                                                                      |
| 485 |    488.316472 |    279.037345 | Amanda Katzer                                                                                                                                                         |
| 486 |     16.182124 |     14.572900 | NA                                                                                                                                                                    |
| 487 |    327.454770 |    194.726974 | NA                                                                                                                                                                    |
| 488 |    351.551772 |    199.233495 | Gareth Monger                                                                                                                                                         |
| 489 |     21.945323 |    320.098490 | Caleb M. Brown                                                                                                                                                        |
| 490 |    431.682894 |     20.682404 | C. Camilo Julián-Caballero                                                                                                                                            |
| 491 |    126.220972 |    242.353352 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 492 |    569.158465 |    792.064526 | Collin Gross                                                                                                                                                          |
| 493 |    773.370431 |    474.657571 | Matt Dempsey                                                                                                                                                          |
| 494 |    185.065244 |    190.643465 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 495 |    629.789379 |    287.330529 | Ingo Braasch                                                                                                                                                          |
| 496 |    179.133027 |      9.995958 | Scott Hartman                                                                                                                                                         |
| 497 |    361.315432 |    779.205686 | Tasman Dixon                                                                                                                                                          |
| 498 |    163.023801 |      5.257228 | Smokeybjb                                                                                                                                                             |
| 499 |    649.617136 |    557.325596 | S.Martini                                                                                                                                                             |
| 500 |     55.487229 |    773.874992 | Emily Willoughby                                                                                                                                                      |
| 501 |    314.056823 |      5.291438 | Scott Hartman                                                                                                                                                         |
| 502 |    816.993117 |    625.024807 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 503 |    401.453254 |    172.281583 | NA                                                                                                                                                                    |
| 504 |    504.618860 |    722.150708 | Zimices                                                                                                                                                               |
| 505 |    299.435939 |    660.939528 | Roberto Díaz Sibaja                                                                                                                                                   |
| 506 |    247.825540 |    790.627904 | Jagged Fang Designs                                                                                                                                                   |
| 507 |    591.292594 |    321.652212 | Andrew A. Farke                                                                                                                                                       |
| 508 |    494.550952 |    492.875193 | Margot Michaud                                                                                                                                                        |
| 509 |    310.346757 |    654.719129 | Scott Hartman                                                                                                                                                         |
| 510 |    611.870839 |    626.978881 | Jagged Fang Designs                                                                                                                                                   |
| 511 |   1013.259520 |    552.098723 | Michele M Tobias                                                                                                                                                      |
| 512 |    103.208348 |    106.178064 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 513 |    975.112475 |    335.143835 | Iain Reid                                                                                                                                                             |
| 514 |    406.604850 |    301.274840 | Gareth Monger                                                                                                                                                         |
| 515 |    850.108586 |    469.480242 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 516 |    610.237282 |    236.139543 | Zimices                                                                                                                                                               |
| 517 |    261.375634 |    550.970224 | Markus A. Grohme                                                                                                                                                      |

    #> Your tweet has been posted!
