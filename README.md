
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

Matt Crook, M Kolmann, Gareth Monger, Tasman Dixon, Christopher Chávez,
Ferran Sayol, Dean Schnabel, Mali’o Kodis, drawing by Manvir Singh,
Steven Traver, Michael Scroggie, Robbie N. Cada (vectorized by T.
Michael Keesey), Margot Michaud, T. Michael Keesey, T. Michael Keesey
(after Kukalová), Taro Maeda, xgirouxb, Xavier Giroux-Bougard, Iain
Reid, Beth Reinke, CDC (Alissa Eckert; Dan Higgins), Ludwik Gasiorowski,
Jaime Headden, Dann Pigdon, Jake Warner, Gabriela Palomo-Munoz, Scott
Hartman, Leann Biancani, photo by Kenneth Clifton, Tauana J. Cunha,
Zimices, Philippe Janvier (vectorized by T. Michael Keesey), Johan
Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Ben
Liebeskind, Ghedoghedo (vectorized by T. Michael Keesey), Dmitry
Bogdanov (modified by T. Michael Keesey), Cathy, Lukasiniho, (unknown),
Smokeybjb (vectorized by T. Michael Keesey), Chris huh, T. Tischler, L.
Shyamal, Henry Lydecker, Kamil S. Jaron, Markus A. Grohme, Michelle
Site, Mike Hanson, Steven Coombs, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Nobu Tamura (vectorized by T. Michael Keesey), Chris A.
Hamilton, Chris Jennings (Risiatto), Alex Slavenko, Yan Wong from
drawing by T. F. Zimmermann, Melissa Broussard, Sarah Werning, Collin
Gross, Noah Schlottman, photo by Carlos Sánchez-Ortiz, Ignacio
Contreras, David Orr, Martin R. Smith, Felix Vaux, Chloé Schmidt, (after
McCulloch 1908), Mathieu Pélissié, Juan Carlos Jerí, Birgit Lang, Sharon
Wegner-Larsen, Andreas Trepte (vectorized by T. Michael Keesey), Mali’o
Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Andy Wilson,
\[unknown\], Richard Lampitt, Jeremy Young / NHM (vectorization by Yan
Wong), T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler,
Ted M. Townsend & Miguel Vences), Martin Kevil, Darius Nau, Lafage,
Kristina Gagalova, Rafael Maia, Jonathan Lawley, Rebecca Groom, C.
Camilo Julián-Caballero, Julia B McHugh, Martien Brand (original photo),
Renato Santos (vector silhouette), Jagged Fang Designs, Marie Russell,
Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T.
Michael Keesey), Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), T. Michael Keesey
(vectorization); Yves Bousquet (photography), Joshua Fowler, Rachel
Shoop, Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Emma Hughes, Cesar Julian, T. Michael
Keesey (vectorization) and HuttyMcphoo (photography), T. Michael Keesey
(after C. De Muizon), Original drawing by Dmitry Bogdanov, vectorized by
Roberto Díaz Sibaja, Emily Jane McTavish, Madeleine Price Ball, Mo
Hassan, T. Michael Keesey (after Colin M. L. Burnett), Smokeybjb, Nobu
Tamura, Mihai Dragos (vectorized by T. Michael Keesey), Lisa Byrne,
Didier Descouens (vectorized by T. Michael Keesey), Darren Naish
(vectorize by T. Michael Keesey), Catherine Yasuda, Matus Valach,
Jessica Anne Miller, Yan Wong from drawing by Joseph Smit, Ellen
Edmonson (illustration) and Timothy J. Bartley (silhouette), Caroline
Harding, MAF (vectorized by T. Michael Keesey), Notafly (vectorized by
T. Michael Keesey), Alexander Schmidt-Lebuhn, Scott Reid, Noah
Schlottman, photo by Adam G. Clause, Matt Celeskey, FunkMonk, Sarah
Alewijnse, Brad McFeeters (vectorized by T. Michael Keesey), DFoidl
(vectorized by T. Michael Keesey), Siobhon Egan, Mali’o Kodis,
photograph by Cordell Expeditions at Cal Academy, Manabu Sakamoto, Kai
R. Caspar, Campbell Fleming, U.S. National Park Service (vectorized by
William Gearty), Pearson Scott Foresman (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Casey Dunn, James Neenan, Lisa M.
“Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Inessa Voet, Pranav Iyer (grey ideas), Nancy Wyman
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Jose Carlos Arenas-Monroy, Birgit Lang, based on a photo by D.
Sikes, Steve Hillebrand/U. S. Fish and Wildlife Service (source photo),
T. Michael Keesey (vectorization), Gopal Murali, Joschua Knüppe, Carlos
Cano-Barbacil, Aline M. Ghilardi, Claus Rebler, Enoch Joseph Wetsy
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on
iNaturalist, Andrew A. Farke, modified from original by Robert Bruce
Horsfall, from Scott 1912, Chuanixn Yu, Dave Angelini, Maky
(vectorization), Gabriella Skollar (photography), Rebecca Lewis
(editing), Kent Elson Sorgon, Mattia Menchetti, Mathieu Basille, Yan
Wong, Tony Ayling (vectorized by Milton Tan), Nicholas J. Czaplewski,
vectorized by Zimices, Maxwell Lefroy (vectorized by T. Michael Keesey),
Nobu Tamura (vectorized by A. Verrière), Fritz Geller-Grimm (vectorized
by T. Michael Keesey), Ralf Janssen, Nikola-Michael Prpic & Wim G. M.
Damen (vectorized by T. Michael Keesey), Joanna Wolfe, Kailah Thorn &
Ben King, Crystal Maier, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Óscar San-Isidro
(vectorized by T. Michael Keesey), Jerry Oldenettel (vectorized by T.
Michael Keesey), Yan Wong from photo by Denes Emoke, S.Martini,
Smokeybjb (modified by Mike Keesey), Renata F. Martins, Joseph Smit
(modified by T. Michael Keesey), Harold N Eyster, Tyler McCraney, Yan
Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo),
Emily Willoughby, Erika Schumacher, Noah Schlottman, Marie-Aimée Allard,
Bennet McComish, photo by Hans Hillewaert, David Sim (photograph) and T.
Michael Keesey (vectorization), Bruno Maggia, V. Deepak, Walter
Vladimir, James R. Spotila and Ray Chatterji, Maija Karala, Katie S.
Collins, Sean McCann, Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, Ingo Braasch, Michele Tobias, Milton Tan,
Christoph Schomburg, Farelli (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Roberto Díaz Sibaja, Mali’o Kodis,
photograph by Hans Hillewaert, Cristina Guijarro, Stanton F. Fink
(vectorized by T. Michael Keesey), Benjamin Monod-Broca, Dinah Challen,
Conty (vectorized by T. Michael Keesey), Nobu Tamura, vectorized by
Zimices, Alexandre Vong, Chase Brownstein, Smith609 and T. Michael
Keesey, Scarlet23 (vectorized by T. Michael Keesey), Becky Barnes, Neil
Kelley, Kosta Mumcuoglu (vectorized by T. Michael Keesey), Paul Baker
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Dmitry Bogdanov, Roderic Page and Lois Page, FJDegrange, Yan
Wong from drawing in The Century Dictionary (1911), Karkemish
(vectorized by T. Michael Keesey), Obsidian Soul (vectorized by T.
Michael Keesey), , Sergio A. Muñoz-Gómez, Armin Reindl, Mercedes Yrayzoz
(vectorized by T. Michael Keesey), Francesca Belem Lopes Palmeira,
Manabu Bessho-Uehara, Ernst Haeckel (vectorized by T. Michael Keesey),
Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Kailah Thorn
& Mark Hutchinson, Mali’o Kodis, photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Agnello Picorelli, I.
Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey), Tony Ayling
(vectorized by T. Michael Keesey), Joseph Wolf, 1863 (vectorization by
Dinah Challen), Kanchi Nanjo, Mathew Wedel, Jack Mayer Wood, Kelly,
Tracy A. Heath, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Caleb M. Brown, Pete Buchholz, Chris Jennings (vectorized by A.
Verrière), Oscar Sanisidro, Eric Moody, Pollyanna von Knorring and T.
Michael Keesey, Mathilde Cordellier, Andrew A. Farke, Jonathan Wells,
John Curtis (vectorized by T. Michael Keesey), Scott D. Sampson, Mark A.
Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua
A. Smith, Alan L. Titus, Arthur S. Brum, Anthony Caravaggi, Maxime
Dahirel, Apokryltaros (vectorized by T. Michael Keesey), Luc Viatour
(source photo) and Andreas Plank, Xavier A. Jenkins, Gabriel Ugueto, DW
Bapst (modified from Bulman, 1970), Zimices / Julián Bayona, Michael B.
H. (vectorized by T. Michael Keesey), Stuart Humphries, Verdilak, Eyal
Bartov, Matt Martyniuk, T. Michael Keesey (after James & al.), Zachary
Quigley

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    187.587982 |    628.891282 | Matt Crook                                                                                                                                                            |
|   2 |    113.467059 |    243.828546 | NA                                                                                                                                                                    |
|   3 |    349.885244 |    719.070940 | M Kolmann                                                                                                                                                             |
|   4 |    706.355153 |    527.192201 | Gareth Monger                                                                                                                                                         |
|   5 |    947.422900 |    266.931394 | Tasman Dixon                                                                                                                                                          |
|   6 |    541.578085 |    666.614098 | Christopher Chávez                                                                                                                                                    |
|   7 |    915.416650 |    722.109976 | NA                                                                                                                                                                    |
|   8 |    586.375933 |    315.713671 | Ferran Sayol                                                                                                                                                          |
|   9 |    657.301198 |    189.909657 | NA                                                                                                                                                                    |
|  10 |    293.074886 |    365.574191 | Dean Schnabel                                                                                                                                                         |
|  11 |    493.734297 |    284.877947 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
|  12 |    932.945700 |    529.847117 | Steven Traver                                                                                                                                                         |
|  13 |    392.896843 |    493.043385 | Michael Scroggie                                                                                                                                                      |
|  14 |    226.180263 |    107.306089 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  15 |    624.836553 |    130.168807 | Matt Crook                                                                                                                                                            |
|  16 |    369.850254 |     64.153165 | Margot Michaud                                                                                                                                                        |
|  17 |    329.428427 |    228.309939 | T. Michael Keesey                                                                                                                                                     |
|  18 |    781.464875 |    117.537144 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
|  19 |     65.976457 |    582.958369 | Taro Maeda                                                                                                                                                            |
|  20 |    557.480712 |    434.285745 | xgirouxb                                                                                                                                                              |
|  21 |    100.259376 |    737.038330 | Xavier Giroux-Bougard                                                                                                                                                 |
|  22 |    834.107826 |     61.912481 | Iain Reid                                                                                                                                                             |
|  23 |    929.408874 |    357.268400 | NA                                                                                                                                                                    |
|  24 |    792.171225 |    701.463819 | Beth Reinke                                                                                                                                                           |
|  25 |    830.568203 |    361.748214 | CDC (Alissa Eckert; Dan Higgins)                                                                                                                                      |
|  26 |     67.198288 |    436.651863 | NA                                                                                                                                                                    |
|  27 |    474.354156 |    748.578959 | Matt Crook                                                                                                                                                            |
|  28 |    382.097248 |    628.818111 | Ludwik Gasiorowski                                                                                                                                                    |
|  29 |    830.198249 |    236.311142 | Jaime Headden                                                                                                                                                         |
|  30 |    924.665127 |    173.347447 | Dann Pigdon                                                                                                                                                           |
|  31 |    512.572559 |    105.489400 | Matt Crook                                                                                                                                                            |
|  32 |    489.372533 |     49.749595 | Jake Warner                                                                                                                                                           |
|  33 |    745.072720 |    737.563030 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  34 |    561.592945 |    268.411467 | Scott Hartman                                                                                                                                                         |
|  35 |    162.225861 |    429.733376 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
|  36 |    552.556820 |    540.094429 | Tauana J. Cunha                                                                                                                                                       |
|  37 |    758.745785 |    289.839762 | Iain Reid                                                                                                                                                             |
|  38 |    740.367887 |    411.010729 | Margot Michaud                                                                                                                                                        |
|  39 |     74.895628 |    133.352271 | Zimices                                                                                                                                                               |
|  40 |    364.505039 |    275.661511 | T. Michael Keesey                                                                                                                                                     |
|  41 |    802.236289 |    609.213515 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
|  42 |    221.264723 |     50.645453 | Jaime Headden                                                                                                                                                         |
|  43 |    379.370851 |    177.975016 | Zimices                                                                                                                                                               |
|  44 |    262.046246 |    669.382304 | Zimices                                                                                                                                                               |
|  45 |    655.763737 |    621.236315 | T. Michael Keesey                                                                                                                                                     |
|  46 |    266.122118 |    738.190751 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
|  47 |     82.729169 |     37.873679 | Margot Michaud                                                                                                                                                        |
|  48 |    930.404805 |     97.773644 | Matt Crook                                                                                                                                                            |
|  49 |    849.475788 |    491.751611 | Ben Liebeskind                                                                                                                                                        |
|  50 |    803.938973 |    210.583871 | Gareth Monger                                                                                                                                                         |
|  51 |    919.453663 |    658.681933 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  52 |    255.880833 |    489.095018 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
|  53 |    217.822694 |    187.564358 | Cathy                                                                                                                                                                 |
|  54 |    641.392714 |     47.561141 | Lukasiniho                                                                                                                                                            |
|  55 |    425.873990 |    552.696093 | (unknown)                                                                                                                                                             |
|  56 |    100.849683 |    696.869045 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
|  57 |    624.000058 |    712.218710 | Margot Michaud                                                                                                                                                        |
|  58 |    552.160111 |    234.991983 | Chris huh                                                                                                                                                             |
|  59 |    840.185355 |    776.682175 | T. Tischler                                                                                                                                                           |
|  60 |    546.913610 |    587.998054 | Chris huh                                                                                                                                                             |
|  61 |    981.657897 |    343.454788 | L. Shyamal                                                                                                                                                            |
|  62 |    582.931057 |    786.210799 | Henry Lydecker                                                                                                                                                        |
|  63 |    475.555076 |    379.534826 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  64 |    287.321477 |    143.753593 | Kamil S. Jaron                                                                                                                                                        |
|  65 |    331.773354 |    430.297805 | Markus A. Grohme                                                                                                                                                      |
|  66 |    170.308178 |    543.402058 | Michelle Site                                                                                                                                                         |
|  67 |    262.606947 |    771.210295 | Mike Hanson                                                                                                                                                           |
|  68 |    774.005287 |    494.352566 | Kamil S. Jaron                                                                                                                                                        |
|  69 |    454.104480 |    714.336391 | Steven Coombs                                                                                                                                                         |
|  70 |    767.987208 |    316.846622 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  71 |    654.703724 |    761.928880 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  72 |    696.576927 |    763.788271 | Margot Michaud                                                                                                                                                        |
|  73 |    650.794517 |    450.065326 | Gareth Monger                                                                                                                                                         |
|  74 |    421.848605 |    575.595013 | Chris A. Hamilton                                                                                                                                                     |
|  75 |    976.877538 |    286.000666 | Ferran Sayol                                                                                                                                                          |
|  76 |    935.292476 |    683.000349 | Chris Jennings (Risiatto)                                                                                                                                             |
|  77 |    420.188279 |    261.939878 | Matt Crook                                                                                                                                                            |
|  78 |    924.374479 |    206.091958 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  79 |    328.913254 |    587.127322 | NA                                                                                                                                                                    |
|  80 |    127.986867 |    529.614637 | Zimices                                                                                                                                                               |
|  81 |    272.331341 |    579.146714 | Alex Slavenko                                                                                                                                                         |
|  82 |    548.105000 |    327.490908 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  83 |    367.694018 |     99.720351 | NA                                                                                                                                                                    |
|  84 |    660.398417 |    420.711430 | Gareth Monger                                                                                                                                                         |
|  85 |    451.807626 |    139.609314 | Gareth Monger                                                                                                                                                         |
|  86 |     44.420922 |    530.436118 | Margot Michaud                                                                                                                                                        |
|  87 |    151.723891 |    550.944907 | NA                                                                                                                                                                    |
|  88 |    501.807566 |    204.116687 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
|  89 |    476.118763 |    598.221524 | Melissa Broussard                                                                                                                                                     |
|  90 |    297.013036 |     97.011610 | Sarah Werning                                                                                                                                                         |
|  91 |    313.542178 |    520.509574 | Tasman Dixon                                                                                                                                                          |
|  92 |    282.045979 |    519.618427 | Matt Crook                                                                                                                                                            |
|  93 |    893.309051 |    416.531640 | Collin Gross                                                                                                                                                          |
|  94 |    837.887971 |    675.039382 | Alex Slavenko                                                                                                                                                         |
|  95 |   1006.523088 |     25.838859 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  96 |    476.651503 |    618.115038 | Gareth Monger                                                                                                                                                         |
|  97 |    192.038739 |    788.824569 | Zimices                                                                                                                                                               |
|  98 |    963.873969 |     31.617881 | NA                                                                                                                                                                    |
|  99 |    916.625461 |     34.548382 | Margot Michaud                                                                                                                                                        |
| 100 |    749.972058 |    361.686454 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 101 |    824.937739 |    657.460376 | Ignacio Contreras                                                                                                                                                     |
| 102 |    616.831596 |    761.986820 | David Orr                                                                                                                                                             |
| 103 |    773.765002 |     29.767492 | Markus A. Grohme                                                                                                                                                      |
| 104 |    637.158795 |    485.031562 | Tasman Dixon                                                                                                                                                          |
| 105 |    926.786084 |    768.665028 | Martin R. Smith                                                                                                                                                       |
| 106 |    417.732731 |    388.946714 | Matt Crook                                                                                                                                                            |
| 107 |    690.832184 |    656.444030 | xgirouxb                                                                                                                                                              |
| 108 |    599.605072 |    287.009457 | Felix Vaux                                                                                                                                                            |
| 109 |    995.096554 |    756.801182 | Chloé Schmidt                                                                                                                                                         |
| 110 |    657.651144 |    547.549702 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 111 |    573.791812 |    368.981120 | (after McCulloch 1908)                                                                                                                                                |
| 112 |    754.579626 |     23.229516 | Matt Crook                                                                                                                                                            |
| 113 |     20.871616 |    512.462930 | Mathieu Pélissié                                                                                                                                                      |
| 114 |    274.270504 |    185.863823 | Zimices                                                                                                                                                               |
| 115 |    367.258932 |     23.328758 | Juan Carlos Jerí                                                                                                                                                      |
| 116 |    405.193973 |    236.394350 | Birgit Lang                                                                                                                                                           |
| 117 |    668.085350 |    385.178143 | Sharon Wegner-Larsen                                                                                                                                                  |
| 118 |    113.353610 |    373.137939 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 119 |     34.116935 |    415.992636 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 120 |    442.390714 |    315.505206 | Andy Wilson                                                                                                                                                           |
| 121 |    402.074389 |    306.024569 | \[unknown\]                                                                                                                                                           |
| 122 |    724.820199 |    326.149607 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 123 |    876.531272 |    221.682149 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 124 |    898.606209 |    636.349151 | Chris huh                                                                                                                                                             |
| 125 |    191.321006 |    361.163345 | Martin Kevil                                                                                                                                                          |
| 126 |    512.759841 |    486.338473 | Darius Nau                                                                                                                                                            |
| 127 |    499.300243 |     12.662977 | Lafage                                                                                                                                                                |
| 128 |     25.237629 |    688.288864 | Markus A. Grohme                                                                                                                                                      |
| 129 |    317.533008 |    492.518570 | Kristina Gagalova                                                                                                                                                     |
| 130 |    936.114149 |    286.790136 | NA                                                                                                                                                                    |
| 131 |    129.493664 |    468.772777 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 132 |    738.384501 |    714.661053 | Rafael Maia                                                                                                                                                           |
| 133 |    826.302439 |    528.535113 | Jonathan Lawley                                                                                                                                                       |
| 134 |    417.908345 |      9.175421 | Steven Traver                                                                                                                                                         |
| 135 |    690.964194 |    161.321670 | Steven Traver                                                                                                                                                         |
| 136 |    397.940780 |    204.862977 | Zimices                                                                                                                                                               |
| 137 |    172.261179 |    166.374168 | Zimices                                                                                                                                                               |
| 138 |    950.486589 |    222.233268 | Matt Crook                                                                                                                                                            |
| 139 |    838.768311 |    632.008333 | Matt Crook                                                                                                                                                            |
| 140 |    587.035263 |    775.836486 | NA                                                                                                                                                                    |
| 141 |    968.901848 |      5.448250 | NA                                                                                                                                                                    |
| 142 |    264.465555 |    118.702764 | T. Michael Keesey                                                                                                                                                     |
| 143 |    943.799353 |    716.476602 | Steven Traver                                                                                                                                                         |
| 144 |    744.309565 |    530.972317 | Rebecca Groom                                                                                                                                                         |
| 145 |     83.831767 |     78.153605 | Kamil S. Jaron                                                                                                                                                        |
| 146 |    307.371149 |    458.710063 | C. Camilo Julián-Caballero                                                                                                                                            |
| 147 |    386.549395 |    782.816542 | Zimices                                                                                                                                                               |
| 148 |    544.459126 |    769.753085 | Julia B McHugh                                                                                                                                                        |
| 149 |    935.012762 |    222.903130 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 150 |    287.353373 |    413.691704 | Chris huh                                                                                                                                                             |
| 151 |    661.614464 |    122.342980 | Matt Crook                                                                                                                                                            |
| 152 |    385.148430 |    238.460639 | Jagged Fang Designs                                                                                                                                                   |
| 153 |    205.238982 |    321.051346 | T. Michael Keesey                                                                                                                                                     |
| 154 |    723.829486 |     53.901108 | T. Michael Keesey                                                                                                                                                     |
| 155 |    596.377808 |    630.752282 | Margot Michaud                                                                                                                                                        |
| 156 |    591.217171 |    672.424052 | NA                                                                                                                                                                    |
| 157 |    619.286863 |    742.621682 | Markus A. Grohme                                                                                                                                                      |
| 158 |    292.162610 |    613.486126 | Marie Russell                                                                                                                                                         |
| 159 |    110.918062 |    471.774039 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 160 |     12.644571 |    377.280070 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 161 |     28.143875 |    208.304523 | Chris Jennings (Risiatto)                                                                                                                                             |
| 162 |    983.324417 |    637.533134 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 163 |    213.102199 |     11.403933 | NA                                                                                                                                                                    |
| 164 |    692.861932 |    583.265387 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 165 |    947.977117 |    283.668121 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 166 |    553.428370 |    725.127573 | Matt Crook                                                                                                                                                            |
| 167 |    954.545646 |    782.951873 | Joshua Fowler                                                                                                                                                         |
| 168 |    963.501763 |    216.529612 | Melissa Broussard                                                                                                                                                     |
| 169 |     65.133725 |    508.929575 | Zimices                                                                                                                                                               |
| 170 |    878.351749 |    256.222965 | Rachel Shoop                                                                                                                                                          |
| 171 |    753.021985 |    775.164187 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 172 |    837.379444 |     16.747536 | Markus A. Grohme                                                                                                                                                      |
| 173 |    808.134382 |    511.794229 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 174 |    246.985036 |     81.097150 | Margot Michaud                                                                                                                                                        |
| 175 |    134.115096 |     19.376336 | Emma Hughes                                                                                                                                                           |
| 176 |    294.231365 |    579.886595 | Zimices                                                                                                                                                               |
| 177 |    574.889064 |    476.262807 | Zimices                                                                                                                                                               |
| 178 |    907.716986 |    347.060690 | Zimices                                                                                                                                                               |
| 179 |    447.629743 |     25.120394 | Ignacio Contreras                                                                                                                                                     |
| 180 |     66.087874 |    749.414970 | Zimices                                                                                                                                                               |
| 181 |    642.465970 |     83.121621 | Cesar Julian                                                                                                                                                          |
| 182 |    999.058404 |    437.305347 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 183 |     19.338292 |    491.752854 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 184 |    381.104652 |    441.194992 | Scott Hartman                                                                                                                                                         |
| 185 |    219.151300 |    716.411849 | Beth Reinke                                                                                                                                                           |
| 186 |    800.484521 |     30.741646 | Zimices                                                                                                                                                               |
| 187 |    556.615952 |    146.118519 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 188 |    990.454361 |    289.631520 | Markus A. Grohme                                                                                                                                                      |
| 189 |    512.391980 |    285.435523 | Emily Jane McTavish                                                                                                                                                   |
| 190 |     12.613326 |    209.758135 | Margot Michaud                                                                                                                                                        |
| 191 |     23.941656 |     96.934885 | Madeleine Price Ball                                                                                                                                                  |
| 192 |    283.977252 |    451.879170 | NA                                                                                                                                                                    |
| 193 |     83.428209 |    362.395865 | Zimices                                                                                                                                                               |
| 194 |    573.734281 |    337.471463 | Zimices                                                                                                                                                               |
| 195 |    442.390728 |    574.573481 | T. Michael Keesey                                                                                                                                                     |
| 196 |    440.480673 |    122.944500 | T. Michael Keesey                                                                                                                                                     |
| 197 |    989.319709 |    396.464504 | Jagged Fang Designs                                                                                                                                                   |
| 198 |    364.686676 |    221.641675 | Zimices                                                                                                                                                               |
| 199 |     68.197054 |      8.120306 | Mo Hassan                                                                                                                                                             |
| 200 |     50.268234 |    634.833496 | Steven Traver                                                                                                                                                         |
| 201 |    888.234671 |    791.301438 | T. Michael Keesey                                                                                                                                                     |
| 202 |    772.793040 |    453.126757 | Scott Hartman                                                                                                                                                         |
| 203 |    102.487069 |     12.892506 | Zimices                                                                                                                                                               |
| 204 |    612.872748 |    581.032604 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                         |
| 205 |    139.233650 |     86.810724 | Smokeybjb                                                                                                                                                             |
| 206 |    641.656475 |    500.776394 | Nobu Tamura                                                                                                                                                           |
| 207 |    880.277984 |     83.653680 | T. Michael Keesey                                                                                                                                                     |
| 208 |   1005.071878 |      5.076643 | Beth Reinke                                                                                                                                                           |
| 209 |    684.017748 |    344.882613 | NA                                                                                                                                                                    |
| 210 |    631.822545 |    403.230893 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 211 |    328.084330 |    762.640738 | Gareth Monger                                                                                                                                                         |
| 212 |    507.076112 |    752.663446 | Lisa Byrne                                                                                                                                                            |
| 213 |    466.980559 |    658.083929 | Zimices                                                                                                                                                               |
| 214 |    859.845839 |    608.680604 | Scott Hartman                                                                                                                                                         |
| 215 |    389.936416 |    388.647234 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 216 |    973.475597 |    727.158336 | NA                                                                                                                                                                    |
| 217 |    154.813955 |    126.015345 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 218 |    483.604308 |    301.769655 | Catherine Yasuda                                                                                                                                                      |
| 219 |    167.004789 |     21.955540 | Michael Scroggie                                                                                                                                                      |
| 220 |    963.556496 |    441.929324 | Matus Valach                                                                                                                                                          |
| 221 |    460.174366 |     98.016100 | Markus A. Grohme                                                                                                                                                      |
| 222 |     24.291424 |    175.707081 | Jessica Anne Miller                                                                                                                                                   |
| 223 |    291.036979 |    789.909283 | Jagged Fang Designs                                                                                                                                                   |
| 224 |    347.036084 |    194.600085 | Matt Crook                                                                                                                                                            |
| 225 |    306.472595 |    412.154964 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 226 |     41.416982 |    521.543553 | Scott Hartman                                                                                                                                                         |
| 227 |    181.263046 |    668.144467 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 228 |    402.782184 |    336.343586 | NA                                                                                                                                                                    |
| 229 |    748.313825 |    330.652337 | Zimices                                                                                                                                                               |
| 230 |    113.698853 |    489.286085 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 231 |    268.826467 |    466.718351 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 232 |    667.149118 |    524.761323 | Tasman Dixon                                                                                                                                                          |
| 233 |    981.573918 |    133.302824 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 234 |    573.846302 |     21.540896 | Scott Reid                                                                                                                                                            |
| 235 |    472.090754 |    691.563044 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 236 |    682.843376 |     27.333494 | Tasman Dixon                                                                                                                                                          |
| 237 |    620.125100 |    419.877527 | Michael Scroggie                                                                                                                                                      |
| 238 |    691.772250 |     75.332539 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 239 |    155.812898 |    358.637797 | Matt Celeskey                                                                                                                                                         |
| 240 |    479.567560 |    787.783676 | FunkMonk                                                                                                                                                              |
| 241 |    895.730934 |     26.600081 | Dean Schnabel                                                                                                                                                         |
| 242 |     12.043347 |    461.438557 | Sarah Alewijnse                                                                                                                                                       |
| 243 |    494.902196 |    564.495657 | Matt Crook                                                                                                                                                            |
| 244 |    252.309868 |    439.651718 | NA                                                                                                                                                                    |
| 245 |    421.670495 |    316.415965 | Gareth Monger                                                                                                                                                         |
| 246 |    303.092709 |    752.885077 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 247 |    304.349227 |    293.675820 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 248 |     20.769579 |    241.586721 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 249 |    485.912472 |     78.610418 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
| 250 |    562.452590 |    746.963572 | Collin Gross                                                                                                                                                          |
| 251 |    234.000191 |    599.499509 | Siobhon Egan                                                                                                                                                          |
| 252 |    542.407929 |    382.617747 | Chris huh                                                                                                                                                             |
| 253 |     25.279765 |    711.457449 | Steven Traver                                                                                                                                                         |
| 254 |     16.584402 |    655.207496 | Ferran Sayol                                                                                                                                                          |
| 255 |    926.336714 |    793.614157 | Felix Vaux                                                                                                                                                            |
| 256 |    877.282779 |    753.448470 | Scott Hartman                                                                                                                                                         |
| 257 |    119.369609 |    649.543491 | Scott Hartman                                                                                                                                                         |
| 258 |    489.019287 |    502.811524 | Matt Crook                                                                                                                                                            |
| 259 |    292.792468 |    760.858959 | Jagged Fang Designs                                                                                                                                                   |
| 260 |    773.055703 |    760.206856 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 261 |    904.087322 |    332.655564 | Michael Scroggie                                                                                                                                                      |
| 262 |    331.802656 |     15.833075 | C. Camilo Julián-Caballero                                                                                                                                            |
| 263 |    797.673328 |     10.576376 | Zimices                                                                                                                                                               |
| 264 |    181.612772 |    346.884038 | Jagged Fang Designs                                                                                                                                                   |
| 265 |    541.141583 |     32.808210 | Manabu Sakamoto                                                                                                                                                       |
| 266 |    543.885256 |    177.041116 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 267 |    729.392899 |    157.203825 | Beth Reinke                                                                                                                                                           |
| 268 |    473.092407 |    188.682822 | Matt Crook                                                                                                                                                            |
| 269 |    963.685575 |    637.423507 | Steven Traver                                                                                                                                                         |
| 270 |    639.062659 |    351.046070 | Michelle Site                                                                                                                                                         |
| 271 |     44.576117 |    163.327436 | Kai R. Caspar                                                                                                                                                         |
| 272 |    647.574376 |    377.035788 | Tauana J. Cunha                                                                                                                                                       |
| 273 |    967.026752 |    189.186993 | Smokeybjb                                                                                                                                                             |
| 274 |    196.878130 |    399.957774 | Chris Jennings (Risiatto)                                                                                                                                             |
| 275 |   1003.361087 |    700.243678 | Campbell Fleming                                                                                                                                                      |
| 276 |     43.093804 |    714.687927 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 277 |    465.932164 |    493.655905 | Martin Kevil                                                                                                                                                          |
| 278 |     21.932980 |    334.023468 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 279 |    607.044905 |    769.817725 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 280 |    152.478612 |    787.404909 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 281 |    626.065222 |    562.464992 | Rebecca Groom                                                                                                                                                         |
| 282 |     18.162006 |    779.671162 | James Neenan                                                                                                                                                          |
| 283 |    957.603920 |    327.510665 | Matt Crook                                                                                                                                                            |
| 284 |    288.908626 |    779.417154 | xgirouxb                                                                                                                                                              |
| 285 |    572.237634 |     70.823793 | Matt Crook                                                                                                                                                            |
| 286 |    213.447976 |    318.156865 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 287 |    102.144216 |    443.160720 | Inessa Voet                                                                                                                                                           |
| 288 |    147.080890 |    104.470143 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 289 |    481.268354 |    281.385806 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 290 |    642.869081 |    738.099681 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 291 |    423.072898 |    593.412380 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 292 |     95.516882 |    644.601173 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 293 |    717.157623 |    131.913152 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 294 |    758.880102 |    236.438872 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 295 |    578.200652 |    689.437994 | Birgit Lang                                                                                                                                                           |
| 296 |    284.835716 |    274.392958 | Gopal Murali                                                                                                                                                          |
| 297 |    186.663969 |    755.624289 | Gopal Murali                                                                                                                                                          |
| 298 |   1011.101705 |    579.585990 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 299 |    959.121625 |    228.420952 | Joschua Knüppe                                                                                                                                                        |
| 300 |    398.646912 |    761.799899 | Ferran Sayol                                                                                                                                                          |
| 301 |    575.863545 |    494.976420 | Dean Schnabel                                                                                                                                                         |
| 302 |    414.787327 |    637.422315 | Steven Traver                                                                                                                                                         |
| 303 |    474.756752 |    534.796861 | Carlos Cano-Barbacil                                                                                                                                                  |
| 304 |    217.044646 |    304.270313 | Zimices                                                                                                                                                               |
| 305 |      5.146355 |     34.715286 | Gareth Monger                                                                                                                                                         |
| 306 |    715.539385 |    649.449436 | NA                                                                                                                                                                    |
| 307 |    175.659347 |    383.387265 | Chris huh                                                                                                                                                             |
| 308 |    798.129420 |    793.521005 | Jaime Headden                                                                                                                                                         |
| 309 |    226.090040 |    146.578985 | Aline M. Ghilardi                                                                                                                                                     |
| 310 |    238.400767 |    265.230786 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 311 |     51.824921 |    364.340262 | Claus Rebler                                                                                                                                                          |
| 312 |    141.707709 |    518.031464 | FunkMonk                                                                                                                                                              |
| 313 |    804.338961 |    747.339976 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 314 |    253.103365 |    195.042524 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 315 |     85.498648 |    179.008891 | Steven Traver                                                                                                                                                         |
| 316 |    729.682437 |    595.956273 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 317 |    708.449499 |    220.927317 | Zimices                                                                                                                                                               |
| 318 |    490.854438 |    269.702336 | Steven Traver                                                                                                                                                         |
| 319 |    699.955685 |    469.771179 | Smokeybjb                                                                                                                                                             |
| 320 |    166.700782 |    122.440613 | Chuanixn Yu                                                                                                                                                           |
| 321 |    583.742539 |    757.072370 | Kamil S. Jaron                                                                                                                                                        |
| 322 |    456.690604 |    697.802192 | NA                                                                                                                                                                    |
| 323 |    689.208179 |    785.424235 | Dave Angelini                                                                                                                                                         |
| 324 |     39.491566 |    347.087055 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                        |
| 325 |   1008.623813 |    160.436579 | Tauana J. Cunha                                                                                                                                                       |
| 326 |    650.788397 |    477.871915 | Jagged Fang Designs                                                                                                                                                   |
| 327 |    964.596558 |    405.478712 | Kent Elson Sorgon                                                                                                                                                     |
| 328 |    425.965906 |    673.823974 | Mattia Menchetti                                                                                                                                                      |
| 329 |    255.478991 |    744.207175 | Mathieu Basille                                                                                                                                                       |
| 330 |    681.320912 |    233.210654 | Chris huh                                                                                                                                                             |
| 331 |     44.695398 |    499.607760 | Yan Wong                                                                                                                                                              |
| 332 |    994.445674 |    774.915614 | Mattia Menchetti                                                                                                                                                      |
| 333 |    938.493534 |     19.864440 | NA                                                                                                                                                                    |
| 334 |    462.867655 |     12.509643 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 335 |    876.307377 |    109.646607 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 336 |     28.789837 |    766.393326 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 337 |    530.394403 |    308.673977 | Tasman Dixon                                                                                                                                                          |
| 338 |     42.721845 |    754.055008 | Beth Reinke                                                                                                                                                           |
| 339 |    299.456474 |     12.606821 | Gareth Monger                                                                                                                                                         |
| 340 |    254.988781 |    277.869078 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 341 |    534.072316 |    732.145208 | Zimices                                                                                                                                                               |
| 342 |    280.134641 |    239.829278 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 343 |    684.109003 |    294.370532 | T. Michael Keesey                                                                                                                                                     |
| 344 |   1010.107365 |    778.170340 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 345 |    533.131582 |    193.518487 | NA                                                                                                                                                                    |
| 346 |    684.559739 |    743.543869 | Gareth Monger                                                                                                                                                         |
| 347 |    387.068666 |    740.280803 | T. Tischler                                                                                                                                                           |
| 348 |    809.141437 |    173.951029 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                  |
| 349 |    582.093021 |    116.808539 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 350 |    558.579263 |    736.355257 | Joanna Wolfe                                                                                                                                                          |
| 351 |    243.137928 |     10.607312 | Kailah Thorn & Ben King                                                                                                                                               |
| 352 |    473.523101 |    671.130037 | Crystal Maier                                                                                                                                                         |
| 353 |    332.632326 |    677.840230 | Gareth Monger                                                                                                                                                         |
| 354 |    559.438906 |    619.893159 | Margot Michaud                                                                                                                                                        |
| 355 |    790.332487 |    172.759353 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 356 |    813.712592 |    127.036741 | Carlos Cano-Barbacil                                                                                                                                                  |
| 357 |    470.087026 |    795.332502 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 358 |    288.440073 |     67.041489 | Margot Michaud                                                                                                                                                        |
| 359 |     12.479242 |    270.245319 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 360 |   1008.657662 |    565.283615 | Matt Crook                                                                                                                                                            |
| 361 |    443.977331 |    216.532325 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 362 |    358.834835 |    237.299081 | NA                                                                                                                                                                    |
| 363 |    748.622599 |    156.742383 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 364 |    158.702271 |     76.594644 | Gareth Monger                                                                                                                                                         |
| 365 |    950.397969 |    243.600883 | Tauana J. Cunha                                                                                                                                                       |
| 366 |     31.803121 |     83.584899 | Joanna Wolfe                                                                                                                                                          |
| 367 |    850.612056 |    293.298792 | S.Martini                                                                                                                                                             |
| 368 |     41.453996 |    779.831617 | Sharon Wegner-Larsen                                                                                                                                                  |
| 369 |    557.340365 |    308.502317 | Mathieu Pélissié                                                                                                                                                      |
| 370 |    379.568134 |    747.511758 | Steven Traver                                                                                                                                                         |
| 371 |    281.088375 |    508.576487 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 372 |    826.469164 |    744.752172 | Jagged Fang Designs                                                                                                                                                   |
| 373 |    480.624416 |    460.635074 | Zimices                                                                                                                                                               |
| 374 |    842.700210 |    270.267804 | Renata F. Martins                                                                                                                                                     |
| 375 |    409.133274 |    409.660144 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                           |
| 376 |    601.898480 |    503.798581 | Zimices                                                                                                                                                               |
| 377 |     96.153938 |    539.770855 | Scott Hartman                                                                                                                                                         |
| 378 |    261.240067 |    258.435644 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 379 |    426.802157 |    427.559589 | Scott Hartman                                                                                                                                                         |
| 380 |    384.003997 |    107.049694 | Tasman Dixon                                                                                                                                                          |
| 381 |    522.673076 |    609.284666 | Margot Michaud                                                                                                                                                        |
| 382 |    805.816178 |    495.152154 | Harold N Eyster                                                                                                                                                       |
| 383 |    913.807942 |      9.543421 | Tyler McCraney                                                                                                                                                        |
| 384 |    200.429106 |    778.450794 | NA                                                                                                                                                                    |
| 385 |    638.179329 |    386.263084 | Gareth Monger                                                                                                                                                         |
| 386 |      8.382936 |    337.101315 | Zimices                                                                                                                                                               |
| 387 |    436.078616 |    415.466157 | Matus Valach                                                                                                                                                          |
| 388 |    863.134914 |    795.626513 | Tasman Dixon                                                                                                                                                          |
| 389 |    702.317323 |    171.558230 | Scott Hartman                                                                                                                                                         |
| 390 |    261.647443 |    405.054518 | Harold N Eyster                                                                                                                                                       |
| 391 |    751.500011 |     71.288160 | NA                                                                                                                                                                    |
| 392 |    383.644872 |    307.757507 | Scott Hartman                                                                                                                                                         |
| 393 |    219.139843 |    676.088588 | T. Michael Keesey                                                                                                                                                     |
| 394 |    969.341491 |    244.911290 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
| 395 |    639.224941 |    595.767600 | Dean Schnabel                                                                                                                                                         |
| 396 |    460.091903 |     37.586743 | NA                                                                                                                                                                    |
| 397 |    997.792159 |    727.682586 | Zimices                                                                                                                                                               |
| 398 |    546.245584 |    632.337608 | Emily Willoughby                                                                                                                                                      |
| 399 |    127.875294 |    553.707144 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
| 400 |    852.884727 |    256.550962 | Dean Schnabel                                                                                                                                                         |
| 401 |    661.064992 |    517.508012 | Margot Michaud                                                                                                                                                        |
| 402 |     95.327428 |    660.890449 | Tauana J. Cunha                                                                                                                                                       |
| 403 |    780.087736 |    670.383398 | Erika Schumacher                                                                                                                                                      |
| 404 |    207.957688 |    426.031161 | Gareth Monger                                                                                                                                                         |
| 405 |    750.753348 |    510.234515 | Jessica Anne Miller                                                                                                                                                   |
| 406 |    922.915618 |    198.031703 | Noah Schlottman                                                                                                                                                       |
| 407 |    695.859457 |    270.537505 | NA                                                                                                                                                                    |
| 408 |    354.397240 |    792.129649 | Birgit Lang                                                                                                                                                           |
| 409 |    725.187166 |    537.486838 | Marie-Aimée Allard                                                                                                                                                    |
| 410 |    306.222697 |    122.446644 | Ferran Sayol                                                                                                                                                          |
| 411 |    310.018253 |    783.579126 | Gareth Monger                                                                                                                                                         |
| 412 |    739.271706 |    274.192809 | Smokeybjb                                                                                                                                                             |
| 413 |    970.936196 |    738.299032 | Steven Traver                                                                                                                                                         |
| 414 |    659.028760 |    773.768494 | Matt Crook                                                                                                                                                            |
| 415 |     25.872080 |    442.159781 | Kai R. Caspar                                                                                                                                                         |
| 416 |    523.859786 |    199.819562 | Matt Crook                                                                                                                                                            |
| 417 |    355.188045 |    595.335364 | Matt Crook                                                                                                                                                            |
| 418 |    550.654359 |    713.860507 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 419 |    886.921870 |     33.679567 | S.Martini                                                                                                                                                             |
| 420 |    808.218738 |    142.859736 | Cesar Julian                                                                                                                                                          |
| 421 |    662.027337 |     20.820843 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 422 |    252.189691 |    713.537639 | Bruno Maggia                                                                                                                                                          |
| 423 |    382.669216 |    331.646400 | V. Deepak                                                                                                                                                             |
| 424 |    184.114805 |    405.023017 | T. Michael Keesey                                                                                                                                                     |
| 425 |    940.668043 |    614.829774 | Walter Vladimir                                                                                                                                                       |
| 426 |    719.153439 |     40.910008 | Margot Michaud                                                                                                                                                        |
| 427 |    598.177638 |     89.164247 | Ferran Sayol                                                                                                                                                          |
| 428 |    989.871248 |    792.894921 | Matt Crook                                                                                                                                                            |
| 429 |    403.090679 |    123.906194 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 430 |    457.631735 |    178.333180 | T. Michael Keesey                                                                                                                                                     |
| 431 |    699.967455 |    674.671041 | Beth Reinke                                                                                                                                                           |
| 432 |    392.852175 |    406.006922 | Maija Karala                                                                                                                                                          |
| 433 |    794.655181 |    760.178170 | NA                                                                                                                                                                    |
| 434 |    502.023869 |    630.723990 | Michelle Site                                                                                                                                                         |
| 435 |    517.359821 |    508.214181 | Margot Michaud                                                                                                                                                        |
| 436 |    773.857151 |    213.407551 | Katie S. Collins                                                                                                                                                      |
| 437 |    478.299057 |    575.498139 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 438 |   1014.825152 |    234.758359 | Birgit Lang                                                                                                                                                           |
| 439 |    637.859386 |    568.110179 | FunkMonk                                                                                                                                                              |
| 440 |    605.649498 |    560.210547 | Sean McCann                                                                                                                                                           |
| 441 |    838.238617 |    196.169345 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 442 |    635.663309 |    512.653339 | Zimices                                                                                                                                                               |
| 443 |     54.931907 |     62.019143 | Ingo Braasch                                                                                                                                                          |
| 444 |     25.404198 |    193.501716 | NA                                                                                                                                                                    |
| 445 |    353.551735 |    395.909376 | Zimices                                                                                                                                                               |
| 446 |    745.181639 |     13.738405 | NA                                                                                                                                                                    |
| 447 |    593.199248 |    337.969576 | Michele Tobias                                                                                                                                                        |
| 448 |    386.833892 |    347.466857 | Gareth Monger                                                                                                                                                         |
| 449 |    696.726807 |    118.094652 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 450 |     83.605419 |    769.999025 | Ferran Sayol                                                                                                                                                          |
| 451 |    630.125186 |    433.490494 | Jagged Fang Designs                                                                                                                                                   |
| 452 |    744.369332 |    557.325499 | NA                                                                                                                                                                    |
| 453 |    731.823439 |    460.943022 | Milton Tan                                                                                                                                                            |
| 454 |    470.709528 |    548.454134 | Birgit Lang                                                                                                                                                           |
| 455 |    337.843870 |    293.769338 | Margot Michaud                                                                                                                                                        |
| 456 |    576.093416 |    303.196239 | NA                                                                                                                                                                    |
| 457 |    897.876629 |    101.296573 | Steven Coombs                                                                                                                                                         |
| 458 |    837.594279 |    215.278291 | Gareth Monger                                                                                                                                                         |
| 459 |    103.809882 |    652.699829 | L. Shyamal                                                                                                                                                            |
| 460 |    726.947396 |    618.271824 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 461 |    332.223449 |      9.223634 | Chris huh                                                                                                                                                             |
| 462 |     81.534311 |    347.794857 | Christoph Schomburg                                                                                                                                                   |
| 463 |     26.263727 |    456.663612 | Ignacio Contreras                                                                                                                                                     |
| 464 |    146.857994 |     64.551192 | NA                                                                                                                                                                    |
| 465 |    175.446304 |     33.553824 | T. Michael Keesey                                                                                                                                                     |
| 466 |    225.293251 |    131.542111 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 467 |    332.680062 |    791.053356 | Margot Michaud                                                                                                                                                        |
| 468 |    673.361122 |    789.700772 | Dean Schnabel                                                                                                                                                         |
| 469 |    303.155540 |    547.629351 | Margot Michaud                                                                                                                                                        |
| 470 |     32.564568 |    168.879640 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 471 |     34.084757 |    741.158633 | Margot Michaud                                                                                                                                                        |
| 472 |    395.019370 |    579.254517 | Zimices                                                                                                                                                               |
| 473 |    315.726027 |    284.026613 | Sarah Werning                                                                                                                                                         |
| 474 |    230.324649 |    253.376445 | Smokeybjb                                                                                                                                                             |
| 475 |     64.365851 |    182.014987 | Roberto Díaz Sibaja                                                                                                                                                   |
| 476 |    872.947025 |    237.915074 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 477 |    516.403532 |    187.213131 | Carlos Cano-Barbacil                                                                                                                                                  |
| 478 |    425.636980 |    215.438334 | Sarah Werning                                                                                                                                                         |
| 479 |    288.859353 |    719.292054 | Chris huh                                                                                                                                                             |
| 480 |   1012.270631 |    380.529271 | T. Michael Keesey                                                                                                                                                     |
| 481 |     16.368508 |    411.250437 | Joanna Wolfe                                                                                                                                                          |
| 482 |    615.497614 |     17.946807 | Ferran Sayol                                                                                                                                                          |
| 483 |    547.492931 |    493.406736 | Dean Schnabel                                                                                                                                                         |
| 484 |    626.400162 |    129.568343 | Tasman Dixon                                                                                                                                                          |
| 485 |    714.406574 |    690.172195 | Chris huh                                                                                                                                                             |
| 486 |    291.733092 |     35.794999 | Beth Reinke                                                                                                                                                           |
| 487 |    997.390884 |    238.379617 | Jagged Fang Designs                                                                                                                                                   |
| 488 |    217.922881 |    417.355007 | T. Michael Keesey                                                                                                                                                     |
| 489 |    662.589376 |    337.259356 | Ben Liebeskind                                                                                                                                                        |
| 490 |    861.875152 |    715.638283 | Steven Traver                                                                                                                                                         |
| 491 |    755.367587 |    546.344119 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 492 |    366.965305 |    441.529328 | Scott Reid                                                                                                                                                            |
| 493 |    219.626540 |    517.401739 | Martin R. Smith                                                                                                                                                       |
| 494 |    103.540831 |    796.103257 | Dean Schnabel                                                                                                                                                         |
| 495 |    867.445580 |    561.366834 | NA                                                                                                                                                                    |
| 496 |    856.916756 |     94.722861 | Matt Crook                                                                                                                                                            |
| 497 |    542.123784 |    200.178617 | NA                                                                                                                                                                    |
| 498 |    973.145426 |    770.855773 | Matt Celeskey                                                                                                                                                         |
| 499 |    258.777253 |    511.404432 | Joanna Wolfe                                                                                                                                                          |
| 500 |    996.731643 |     74.523027 | Christoph Schomburg                                                                                                                                                   |
| 501 |    353.843509 |    313.171104 | Cristina Guijarro                                                                                                                                                     |
| 502 |   1014.075220 |    181.551300 | T. Michael Keesey                                                                                                                                                     |
| 503 |    641.948674 |    777.063345 | Margot Michaud                                                                                                                                                        |
| 504 |    940.253066 |    565.661047 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 505 |    390.466806 |     18.423212 | Steven Traver                                                                                                                                                         |
| 506 |    543.942391 |    741.697261 | Lafage                                                                                                                                                                |
| 507 |    517.907315 |    165.978031 | Michael Scroggie                                                                                                                                                      |
| 508 |    172.042195 |    157.806286 | Steven Coombs                                                                                                                                                         |
| 509 |    104.653985 |    508.143880 | Sharon Wegner-Larsen                                                                                                                                                  |
| 510 |    819.685788 |    429.871649 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 511 |    889.193770 |    399.051818 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 512 |    451.090204 |    786.721217 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 513 |    579.943925 |    109.986929 | Benjamin Monod-Broca                                                                                                                                                  |
| 514 |    754.667599 |    131.314237 | Rafael Maia                                                                                                                                                           |
| 515 |     16.395665 |    759.858482 | Markus A. Grohme                                                                                                                                                      |
| 516 |     24.621829 |    300.146189 | Dinah Challen                                                                                                                                                         |
| 517 |    302.635816 |    516.160766 | NA                                                                                                                                                                    |
| 518 |    524.612656 |    758.958165 | Matt Crook                                                                                                                                                            |
| 519 |    995.638328 |    109.105281 | Zimices                                                                                                                                                               |
| 520 |    754.528770 |    572.921481 | Steven Traver                                                                                                                                                         |
| 521 |    730.659394 |    126.788644 | Katie S. Collins                                                                                                                                                      |
| 522 |     67.877973 |    659.899534 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 523 |   1014.582809 |    244.188669 | Steven Traver                                                                                                                                                         |
| 524 |    268.099164 |     20.044320 | Cesar Julian                                                                                                                                                          |
| 525 |   1003.040882 |    647.738602 | NA                                                                                                                                                                    |
| 526 |    653.075587 |    152.365111 | Margot Michaud                                                                                                                                                        |
| 527 |     13.183892 |     59.857326 | Jagged Fang Designs                                                                                                                                                   |
| 528 |    145.825360 |    496.614519 | NA                                                                                                                                                                    |
| 529 |    313.525733 |    643.342985 | Jagged Fang Designs                                                                                                                                                   |
| 530 |    741.207522 |     51.368117 | Zimices                                                                                                                                                               |
| 531 |    252.502670 |    372.981576 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 532 |     14.962516 |     77.695227 | M Kolmann                                                                                                                                                             |
| 533 |    896.800802 |    311.605117 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 534 |    612.174921 |    536.318012 | Birgit Lang                                                                                                                                                           |
| 535 |    153.619153 |    143.652880 | Alexandre Vong                                                                                                                                                        |
| 536 |    256.904407 |    494.574326 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 537 |    129.774417 |    347.197395 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 538 |    285.096429 |    258.198323 | Steven Traver                                                                                                                                                         |
| 539 |    814.319446 |    300.862107 | Gareth Monger                                                                                                                                                         |
| 540 |    698.749217 |    638.020383 | Zimices                                                                                                                                                               |
| 541 |    408.096292 |    433.143302 | NA                                                                                                                                                                    |
| 542 |    731.181092 |    224.275672 | Zimices                                                                                                                                                               |
| 543 |    586.789139 |    150.378915 | Matt Crook                                                                                                                                                            |
| 544 |    711.009097 |    619.204823 | Rebecca Groom                                                                                                                                                         |
| 545 |    854.182484 |    655.325304 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 546 |     24.968648 |    732.581865 | Erika Schumacher                                                                                                                                                      |
| 547 |     27.327408 |    699.916001 | Kai R. Caspar                                                                                                                                                         |
| 548 |    837.212061 |    552.451064 | xgirouxb                                                                                                                                                              |
| 549 |    608.146355 |     80.192046 | M Kolmann                                                                                                                                                             |
| 550 |    478.343979 |    484.500924 | Matt Crook                                                                                                                                                            |
| 551 |    706.606307 |    247.896985 | Margot Michaud                                                                                                                                                        |
| 552 |     20.237619 |     27.987354 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 553 |    150.290697 |    575.011414 | Chase Brownstein                                                                                                                                                      |
| 554 |    248.381859 |    287.219547 | Dean Schnabel                                                                                                                                                         |
| 555 |    360.563544 |    777.570204 | T. Michael Keesey                                                                                                                                                     |
| 556 |    890.761723 |    748.928915 | Markus A. Grohme                                                                                                                                                      |
| 557 |    162.436664 |    760.814942 | Ferran Sayol                                                                                                                                                          |
| 558 |    940.550249 |    703.409267 | L. Shyamal                                                                                                                                                            |
| 559 |    976.780989 |    212.633614 | Margot Michaud                                                                                                                                                        |
| 560 |   1005.881336 |     41.040248 | Michelle Site                                                                                                                                                         |
| 561 |    558.492639 |    298.450932 | Ignacio Contreras                                                                                                                                                     |
| 562 |   1005.547525 |    208.753084 | Andy Wilson                                                                                                                                                           |
| 563 |     77.763363 |    507.535841 | Smith609 and T. Michael Keesey                                                                                                                                        |
| 564 |    436.532015 |    294.005224 | Rebecca Groom                                                                                                                                                         |
| 565 |     49.032956 |     45.691002 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 566 |    542.551779 |    302.763667 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 567 |    410.862093 |    423.278695 | Ignacio Contreras                                                                                                                                                     |
| 568 |    442.140499 |    160.807819 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 569 |    915.731597 |    152.544716 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 570 |     75.996144 |    372.594078 | Zimices                                                                                                                                                               |
| 571 |    120.260423 |    707.976225 | Markus A. Grohme                                                                                                                                                      |
| 572 |    144.274012 |     98.804922 | Jagged Fang Designs                                                                                                                                                   |
| 573 |    272.789015 |    711.973803 | Gareth Monger                                                                                                                                                         |
| 574 |    697.473266 |    342.698711 | Becky Barnes                                                                                                                                                          |
| 575 |    824.882707 |    209.941299 | Scott Hartman                                                                                                                                                         |
| 576 |    274.045336 |    587.016815 | NA                                                                                                                                                                    |
| 577 |     17.294951 |    540.003308 | Scott Hartman                                                                                                                                                         |
| 578 |    664.919581 |    147.451070 | Gareth Monger                                                                                                                                                         |
| 579 |    764.856806 |    388.963616 | Mathieu Pélissié                                                                                                                                                      |
| 580 |    696.872935 |    622.517211 | Gareth Monger                                                                                                                                                         |
| 581 |    832.775971 |    142.103432 | Matt Crook                                                                                                                                                            |
| 582 |    999.277759 |    625.717898 | Neil Kelley                                                                                                                                                           |
| 583 |    191.961923 |    337.255840 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 584 |    116.508297 |    394.505765 | Gareth Monger                                                                                                                                                         |
| 585 |    703.361898 |    321.314038 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 586 |    329.450374 |    777.785976 | Alex Slavenko                                                                                                                                                         |
| 587 |    172.111516 |    704.256288 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 588 |    983.806326 |     23.443895 | Andy Wilson                                                                                                                                                           |
| 589 |    458.829286 |    196.696345 | V. Deepak                                                                                                                                                             |
| 590 |    861.550132 |    725.441811 | Matt Crook                                                                                                                                                            |
| 591 |    589.535280 |      6.917235 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 592 |    303.941219 |     41.828973 | NA                                                                                                                                                                    |
| 593 |    170.028035 |     10.948610 | NA                                                                                                                                                                    |
| 594 |    951.526399 |    313.093599 | T. Michael Keesey                                                                                                                                                     |
| 595 |    949.372745 |    152.946498 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 596 |    220.172765 |    774.816595 | Jagged Fang Designs                                                                                                                                                   |
| 597 |    721.728307 |     87.971618 | NA                                                                                                                                                                    |
| 598 |      8.998734 |    290.572303 | Joshua Fowler                                                                                                                                                         |
| 599 |    316.030252 |    304.330145 | Dmitry Bogdanov                                                                                                                                                       |
| 600 |    595.279903 |     73.806436 | Matt Crook                                                                                                                                                            |
| 601 |    894.541140 |    781.831729 | Noah Schlottman                                                                                                                                                       |
| 602 |    956.948991 |    423.909349 | Margot Michaud                                                                                                                                                        |
| 603 |    987.133769 |    711.701589 | Roderic Page and Lois Page                                                                                                                                            |
| 604 |    552.232855 |     47.674839 | NA                                                                                                                                                                    |
| 605 |    535.540459 |    165.363787 | Ignacio Contreras                                                                                                                                                     |
| 606 |    858.095924 |    187.517175 | Birgit Lang                                                                                                                                                           |
| 607 |    606.396407 |    157.972492 | Jagged Fang Designs                                                                                                                                                   |
| 608 |    949.832415 |    735.760620 | Andy Wilson                                                                                                                                                           |
| 609 |    207.822114 |    710.228378 | FJDegrange                                                                                                                                                            |
| 610 |    461.755498 |    778.015450 | NA                                                                                                                                                                    |
| 611 |    989.212552 |    406.738012 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
| 612 |    986.546147 |    240.956683 | NA                                                                                                                                                                    |
| 613 |    783.425142 |    163.646913 | Gareth Monger                                                                                                                                                         |
| 614 |    358.756054 |    138.132976 | Yan Wong                                                                                                                                                              |
| 615 |    190.898140 |    156.721538 | Steven Traver                                                                                                                                                         |
| 616 |    587.369446 |    463.763138 | Matt Crook                                                                                                                                                            |
| 617 |    641.048554 |    237.986569 | Gareth Monger                                                                                                                                                         |
| 618 |    271.680056 |    785.872422 | Katie S. Collins                                                                                                                                                      |
| 619 |    125.910678 |    364.970529 | Chris huh                                                                                                                                                             |
| 620 |    293.665857 |    479.195679 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 621 |    331.690088 |    311.681472 | David Orr                                                                                                                                                             |
| 622 |   1007.635104 |    793.037243 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 623 |    813.675064 |    551.067938 | Matt Crook                                                                                                                                                            |
| 624 |    902.451839 |    384.171905 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 625 |    254.625819 |    248.722183 | Matt Crook                                                                                                                                                            |
| 626 |    898.055924 |     82.058824 | NA                                                                                                                                                                    |
| 627 |    927.666900 |    247.440599 | Michael Scroggie                                                                                                                                                      |
| 628 |    368.085494 |    408.128020 |                                                                                                                                                                       |
| 629 |    633.593075 |    141.681848 | Matt Crook                                                                                                                                                            |
| 630 |    631.730092 |    784.642793 | Inessa Voet                                                                                                                                                           |
| 631 |    626.734415 |    526.292199 | Zimices                                                                                                                                                               |
| 632 |    150.020789 |     39.784251 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 633 |    809.241614 |    156.141515 | NA                                                                                                                                                                    |
| 634 |    886.132661 |    795.070939 | Chuanixn Yu                                                                                                                                                           |
| 635 |    165.177725 |    139.713320 | Michael Scroggie                                                                                                                                                      |
| 636 |    204.116276 |    496.245304 | NA                                                                                                                                                                    |
| 637 |    173.739964 |    659.447051 | Scott Hartman                                                                                                                                                         |
| 638 |   1000.686908 |    637.128435 | Jagged Fang Designs                                                                                                                                                   |
| 639 |     91.160910 |    497.159679 | Rebecca Groom                                                                                                                                                         |
| 640 |      6.923465 |    452.445813 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 641 |    492.814818 |    760.457786 | Rebecca Groom                                                                                                                                                         |
| 642 |   1013.917855 |     95.643780 | Matt Crook                                                                                                                                                            |
| 643 |    626.079957 |    748.299908 | Tasman Dixon                                                                                                                                                          |
| 644 |     13.919924 |    737.973864 | Armin Reindl                                                                                                                                                          |
| 645 |    729.384539 |    549.299064 | Carlos Cano-Barbacil                                                                                                                                                  |
| 646 |    873.573036 |    289.569119 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 647 |    134.787039 |    713.190870 | Zimices                                                                                                                                                               |
| 648 |    723.431612 |    506.284650 | Chris huh                                                                                                                                                             |
| 649 |    354.286776 |    411.943492 | Margot Michaud                                                                                                                                                        |
| 650 |    766.590569 |    193.102466 | Iain Reid                                                                                                                                                             |
| 651 |    744.573283 |    140.246323 | Francesca Belem Lopes Palmeira                                                                                                                                        |
| 652 |    425.790363 |    322.029309 | Xavier Giroux-Bougard                                                                                                                                                 |
| 653 |    336.522435 |    654.292722 | Alexandre Vong                                                                                                                                                        |
| 654 |   1007.404455 |    463.986903 | Jagged Fang Designs                                                                                                                                                   |
| 655 |    195.868328 |    722.197258 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 656 |    115.463573 |     74.995574 | Gareth Monger                                                                                                                                                         |
| 657 |    997.079814 |    176.283765 | T. Michael Keesey                                                                                                                                                     |
| 658 |    523.729030 |    742.943944 | Michelle Site                                                                                                                                                         |
| 659 |    814.848657 |     41.471880 | Tasman Dixon                                                                                                                                                          |
| 660 |    253.439701 |    524.760414 | Manabu Bessho-Uehara                                                                                                                                                  |
| 661 |    403.074921 |    728.790035 | Gareth Monger                                                                                                                                                         |
| 662 |     24.060641 |    106.452278 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 663 |    437.878014 |    242.918861 | Dean Schnabel                                                                                                                                                         |
| 664 |    430.057881 |    231.912400 | David Orr                                                                                                                                                             |
| 665 |    718.223751 |    641.531058 | FunkMonk                                                                                                                                                              |
| 666 |    116.357297 |    407.385542 | Chris huh                                                                                                                                                             |
| 667 |    680.316369 |    532.629341 | Chris huh                                                                                                                                                             |
| 668 |    419.972922 |    123.586644 | NA                                                                                                                                                                    |
| 669 |    948.470691 |    335.907970 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 670 |    134.387691 |    580.692535 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 671 |    445.019096 |    251.716705 | Margot Michaud                                                                                                                                                        |
| 672 |    576.673841 |    390.490000 | T. Michael Keesey                                                                                                                                                     |
| 673 |    448.450008 |    734.398961 | Jagged Fang Designs                                                                                                                                                   |
| 674 |    419.000240 |     94.100391 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 675 |    417.653309 |    343.613326 | NA                                                                                                                                                                    |
| 676 |    722.091923 |    174.361678 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 677 |    235.255773 |    120.547037 | Maija Karala                                                                                                                                                          |
| 678 |    264.994739 |    269.336845 | Zimices                                                                                                                                                               |
| 679 |    993.607278 |    278.434322 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 680 |     27.414487 |    723.298256 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 681 |    473.431244 |    174.613945 | Matt Crook                                                                                                                                                            |
| 682 |    729.971398 |    638.993046 | Scott Reid                                                                                                                                                            |
| 683 |   1013.642027 |    432.656964 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 684 |    429.806914 |    752.398554 | Jagged Fang Designs                                                                                                                                                   |
| 685 |    492.847120 |    171.151912 | Ignacio Contreras                                                                                                                                                     |
| 686 |    660.543826 |     79.809649 | Nobu Tamura                                                                                                                                                           |
| 687 |    905.232390 |    319.773990 | NA                                                                                                                                                                    |
| 688 |    512.163647 |    564.547813 | Ferran Sayol                                                                                                                                                          |
| 689 |    455.574818 |    671.369361 | Rebecca Groom                                                                                                                                                         |
| 690 |    893.688653 |     53.825561 | Dean Schnabel                                                                                                                                                         |
| 691 |    737.525166 |    611.688219 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 692 |   1004.432161 |    690.442789 | Felix Vaux                                                                                                                                                            |
| 693 |    208.323654 |    268.123611 | Zimices                                                                                                                                                               |
| 694 |    687.098977 |    433.692058 | Jake Warner                                                                                                                                                           |
| 695 |    462.431427 |     81.656073 | Ignacio Contreras                                                                                                                                                     |
| 696 |    963.608941 |    703.983537 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 697 |    898.545730 |    369.382085 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 698 |     47.270357 |      7.575594 | Agnello Picorelli                                                                                                                                                     |
| 699 |    561.060137 |    128.984850 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 700 |    996.953896 |    658.037191 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 701 |    946.702966 |    195.434265 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 702 |    331.448543 |    751.532648 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 703 |    179.500224 |    130.208034 | T. Michael Keesey                                                                                                                                                     |
| 704 |    230.712194 |    449.216281 | NA                                                                                                                                                                    |
| 705 |    821.397483 |    489.011416 | Chris huh                                                                                                                                                             |
| 706 |     96.319317 |    414.665455 | Melissa Broussard                                                                                                                                                     |
| 707 |     63.642077 |    766.915182 | Gareth Monger                                                                                                                                                         |
| 708 |    624.977696 |     17.063163 | Ferran Sayol                                                                                                                                                          |
| 709 |    432.679394 |    146.673135 | Margot Michaud                                                                                                                                                        |
| 710 |    220.324663 |    283.163770 | Kanchi Nanjo                                                                                                                                                          |
| 711 |    376.141353 |    126.821615 | Steven Traver                                                                                                                                                         |
| 712 |    235.340705 |    279.876839 | Margot Michaud                                                                                                                                                        |
| 713 |    808.718144 |    123.363089 | Henry Lydecker                                                                                                                                                        |
| 714 |    269.279374 |    224.046635 | NA                                                                                                                                                                    |
| 715 |    820.848051 |     32.046954 | Sarah Werning                                                                                                                                                         |
| 716 |     21.456527 |    673.531277 | NA                                                                                                                                                                    |
| 717 |    756.597283 |    200.517721 | Zimices                                                                                                                                                               |
| 718 |    253.181979 |    529.210304 | Mathew Wedel                                                                                                                                                          |
| 719 |    984.941599 |      7.758478 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 720 |    342.345813 |    440.274724 | Chris huh                                                                                                                                                             |
| 721 |     16.176992 |    128.269740 | Gareth Monger                                                                                                                                                         |
| 722 |    444.327600 |    588.308250 | Jack Mayer Wood                                                                                                                                                       |
| 723 |    322.382795 |    113.351624 | Iain Reid                                                                                                                                                             |
| 724 |   1009.353347 |    613.170638 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 725 |    276.375238 |    441.152154 | Steven Traver                                                                                                                                                         |
| 726 |    563.253759 |     45.297510 | Kelly                                                                                                                                                                 |
| 727 |    610.085106 |     97.452107 | Markus A. Grohme                                                                                                                                                      |
| 728 |    221.367950 |    535.341023 | Inessa Voet                                                                                                                                                           |
| 729 |    660.202576 |    534.516022 | NA                                                                                                                                                                    |
| 730 |    726.754961 |    237.717764 | S.Martini                                                                                                                                                             |
| 731 |     75.253567 |    648.183239 | Matt Crook                                                                                                                                                            |
| 732 |    834.181836 |     30.947197 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 733 |    484.162920 |    249.635412 | Margot Michaud                                                                                                                                                        |
| 734 |    402.978288 |    113.692077 | Jagged Fang Designs                                                                                                                                                   |
| 735 |    760.518377 |    788.213728 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 736 |    657.452014 |    231.416893 | Matt Crook                                                                                                                                                            |
| 737 |    124.333694 |    354.688176 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 738 |    423.240900 |    646.599683 | Sean McCann                                                                                                                                                           |
| 739 |    175.230855 |    746.770996 | Chris huh                                                                                                                                                             |
| 740 |    873.582830 |    779.797250 | Kamil S. Jaron                                                                                                                                                        |
| 741 |     12.239634 |    360.982111 | Steven Traver                                                                                                                                                         |
| 742 |    883.471989 |    211.082770 | NA                                                                                                                                                                    |
| 743 |     21.567649 |     51.729357 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 744 |    933.309203 |    146.690671 | Ferran Sayol                                                                                                                                                          |
| 745 |    223.144546 |    436.105479 | Ludwik Gasiorowski                                                                                                                                                    |
| 746 |    994.130266 |    421.154198 | Michael Scroggie                                                                                                                                                      |
| 747 |    392.340182 |    250.456936 | Zimices                                                                                                                                                               |
| 748 |    175.154767 |    731.311226 | Scott Hartman                                                                                                                                                         |
| 749 |    698.099394 |    666.579975 | Scott Hartman                                                                                                                                                         |
| 750 |    707.355425 |     15.366704 | Armin Reindl                                                                                                                                                          |
| 751 |    485.065200 |    433.609841 | Scott Hartman                                                                                                                                                         |
| 752 |    999.550017 |    672.016206 | Tracy A. Heath                                                                                                                                                        |
| 753 |    369.747324 |    766.293943 | T. Michael Keesey                                                                                                                                                     |
| 754 |    934.171588 |    604.992203 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 755 |    519.170622 |    630.934634 | Emily Willoughby                                                                                                                                                      |
| 756 |   1015.813130 |    269.556159 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 757 |     91.154695 |    786.422534 | Zimices                                                                                                                                                               |
| 758 |    936.936140 |    441.959279 | NA                                                                                                                                                                    |
| 759 |    242.436705 |    500.356536 | Jagged Fang Designs                                                                                                                                                   |
| 760 |    157.623849 |    793.338949 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 761 |    804.390403 |    438.741153 | Margot Michaud                                                                                                                                                        |
| 762 |    535.546314 |    555.577699 | David Orr                                                                                                                                                             |
| 763 |    257.134426 |    302.900595 | Gareth Monger                                                                                                                                                         |
| 764 |    881.631458 |     94.457397 | Caleb M. Brown                                                                                                                                                        |
| 765 |    886.765520 |    320.019728 | Jack Mayer Wood                                                                                                                                                       |
| 766 |    642.675480 |     14.743094 | NA                                                                                                                                                                    |
| 767 |    774.007222 |    572.516445 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 768 |     98.088257 |    170.804689 | NA                                                                                                                                                                    |
| 769 |    134.558975 |    609.181695 | Jagged Fang Designs                                                                                                                                                   |
| 770 |    774.475229 |    467.020895 | Pete Buchholz                                                                                                                                                         |
| 771 |     11.753067 |    772.628423 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 772 |    453.498685 |    571.679405 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 773 |     25.400893 |    358.433028 | Oscar Sanisidro                                                                                                                                                       |
| 774 |     48.501261 |    694.819729 | Eric Moody                                                                                                                                                            |
| 775 |     11.765587 |    790.909402 | Chris huh                                                                                                                                                             |
| 776 |    720.400435 |    480.771791 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 777 |    776.928061 |    301.985877 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 778 |    705.001610 |    483.687995 | Mathilde Cordellier                                                                                                                                                   |
| 779 |    711.685636 |    783.348416 | Ferran Sayol                                                                                                                                                          |
| 780 |    467.565678 |    628.782644 | Jagged Fang Designs                                                                                                                                                   |
| 781 |    727.053316 |      9.041981 | Andrew A. Farke                                                                                                                                                       |
| 782 |    216.245132 |    138.933289 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 783 |    257.412098 |    563.640569 | Jonathan Wells                                                                                                                                                        |
| 784 |    727.264420 |    678.032525 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 785 |    762.956064 |    653.208663 | Erika Schumacher                                                                                                                                                      |
| 786 |    996.292296 |     58.494884 | Chase Brownstein                                                                                                                                                      |
| 787 |    308.538794 |    595.760167 | Margot Michaud                                                                                                                                                        |
| 788 |    272.262330 |    759.103018 | Smokeybjb                                                                                                                                                             |
| 789 |    155.531963 |    688.944151 | T. Michael Keesey                                                                                                                                                     |
| 790 |    105.168322 |    634.754206 | Andrew A. Farke                                                                                                                                                       |
| 791 |    757.193052 |      8.498847 | Zimices                                                                                                                                                               |
| 792 |    133.298160 |     75.321167 | Neil Kelley                                                                                                                                                           |
| 793 |    148.347450 |     79.960052 | Dean Schnabel                                                                                                                                                         |
| 794 |     75.481513 |    793.431739 | Jagged Fang Designs                                                                                                                                                   |
| 795 |    801.528508 |    657.479760 | Jagged Fang Designs                                                                                                                                                   |
| 796 |    469.569181 |    215.310823 | T. Michael Keesey                                                                                                                                                     |
| 797 |    732.700306 |    258.173820 | Chris huh                                                                                                                                                             |
| 798 |     31.638740 |     34.561173 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 799 |    189.091635 |    732.522100 | NA                                                                                                                                                                    |
| 800 |     69.972653 |     59.859160 | Xavier Giroux-Bougard                                                                                                                                                 |
| 801 |    873.980084 |    277.480772 | Harold N Eyster                                                                                                                                                       |
| 802 |    950.683211 |    574.817455 | Zimices                                                                                                                                                               |
| 803 |     45.165543 |    652.697254 | Chris huh                                                                                                                                                             |
| 804 |    793.947312 |    579.373550 | Steven Coombs                                                                                                                                                         |
| 805 |    786.775487 |    302.184475 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 806 |    943.021711 |     12.441303 | NA                                                                                                                                                                    |
| 807 |    563.519187 |    501.569089 | Margot Michaud                                                                                                                                                        |
| 808 |    969.352832 |    680.755448 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 809 |    374.263478 |    686.058637 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 810 |     38.891685 |     96.236249 | NA                                                                                                                                                                    |
| 811 |    888.117206 |    155.293976 | Arthur S. Brum                                                                                                                                                        |
| 812 |    419.564401 |    111.608096 | Anthony Caravaggi                                                                                                                                                     |
| 813 |     33.231459 |    214.296946 | Zimices                                                                                                                                                               |
| 814 |    860.181457 |    265.468025 | Michele Tobias                                                                                                                                                        |
| 815 |    777.045323 |    187.947901 | Christoph Schomburg                                                                                                                                                   |
| 816 |     32.431789 |    502.261150 | Margot Michaud                                                                                                                                                        |
| 817 |   1017.963450 |    340.786750 | Maxime Dahirel                                                                                                                                                        |
| 818 |    157.549137 |    512.862632 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 819 |    961.594826 |    335.833072 | Jagged Fang Designs                                                                                                                                                   |
| 820 |    810.870128 |    526.834316 | Matt Crook                                                                                                                                                            |
| 821 |    233.936724 |    389.216323 | Jagged Fang Designs                                                                                                                                                   |
| 822 |    109.896613 |    540.028605 | Matt Crook                                                                                                                                                            |
| 823 |    705.155518 |    297.155865 | Milton Tan                                                                                                                                                            |
| 824 |    718.599819 |    240.027997 | Gareth Monger                                                                                                                                                         |
| 825 |    134.301917 |    783.413978 | Manabu Sakamoto                                                                                                                                                       |
| 826 |    817.372557 |    216.057765 | Gareth Monger                                                                                                                                                         |
| 827 |    283.903835 |    224.008551 | Bruno Maggia                                                                                                                                                          |
| 828 |    961.304314 |    297.778703 | NA                                                                                                                                                                    |
| 829 |      8.173720 |    324.285770 | David Orr                                                                                                                                                             |
| 830 |    696.544593 |    682.016773 | Mathieu Basille                                                                                                                                                       |
| 831 |    692.178221 |    393.103896 | Cesar Julian                                                                                                                                                          |
| 832 |     31.711214 |    794.807511 | Tasman Dixon                                                                                                                                                          |
| 833 |    627.521848 |    252.889686 | Sharon Wegner-Larsen                                                                                                                                                  |
| 834 |      7.720382 |    436.142775 | Andy Wilson                                                                                                                                                           |
| 835 |    289.646682 |    214.361134 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 836 |   1011.566822 |    660.820626 | Birgit Lang                                                                                                                                                           |
| 837 |    201.874272 |    224.574964 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 838 |    720.325536 |    304.979062 | Margot Michaud                                                                                                                                                        |
| 839 |    938.910136 |     41.259827 | Kai R. Caspar                                                                                                                                                         |
| 840 |    637.510400 |    581.797802 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 841 |    669.472618 |    502.269105 | Chris huh                                                                                                                                                             |
| 842 |    320.852123 |    257.380093 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
| 843 |    863.368781 |    232.000253 | Ferran Sayol                                                                                                                                                          |
| 844 |    180.477324 |    567.017119 | Gareth Monger                                                                                                                                                         |
| 845 |    539.872226 |    152.208181 | Zimices                                                                                                                                                               |
| 846 |      9.440285 |    245.889880 | T. Michael Keesey                                                                                                                                                     |
| 847 |   1002.123102 |    443.053919 | Ferran Sayol                                                                                                                                                          |
| 848 |    205.227452 |    465.075399 | Zimices                                                                                                                                                               |
| 849 |    861.559387 |     33.571615 | Tauana J. Cunha                                                                                                                                                       |
| 850 |    424.079232 |     63.776729 | Matt Crook                                                                                                                                                            |
| 851 |    942.784796 |    262.495581 | Scott Hartman                                                                                                                                                         |
| 852 |    231.034853 |     79.916340 | Pete Buchholz                                                                                                                                                         |
| 853 |    664.684525 |    371.896796 | Scott Hartman                                                                                                                                                         |
| 854 |    829.008378 |      7.002529 | Ferran Sayol                                                                                                                                                          |
| 855 |    976.345087 |    152.082361 | Jagged Fang Designs                                                                                                                                                   |
| 856 |    747.398880 |    307.902360 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 857 |    564.634242 |    314.012438 | Scott Hartman                                                                                                                                                         |
| 858 |    404.469716 |    219.910424 | Zimices                                                                                                                                                               |
| 859 |    866.903958 |    639.845443 | Matt Crook                                                                                                                                                            |
| 860 |    105.224328 |    421.224847 | Andrew A. Farke                                                                                                                                                       |
| 861 |    222.120797 |    609.230058 | Zimices / Julián Bayona                                                                                                                                               |
| 862 |    198.176166 |    211.545885 | T. Michael Keesey                                                                                                                                                     |
| 863 |    984.349063 |    691.680209 | Kai R. Caspar                                                                                                                                                         |
| 864 |    169.140940 |     49.001556 | Steven Traver                                                                                                                                                         |
| 865 |    666.155287 |    741.220705 | Kai R. Caspar                                                                                                                                                         |
| 866 |    391.588972 |    755.462943 | Ferran Sayol                                                                                                                                                          |
| 867 |    720.951108 |    143.069204 | Margot Michaud                                                                                                                                                        |
| 868 |     62.364093 |    150.572787 | Ferran Sayol                                                                                                                                                          |
| 869 |    773.575314 |    434.480548 | FunkMonk                                                                                                                                                              |
| 870 |    631.290343 |    469.236252 | Chris huh                                                                                                                                                             |
| 871 |    958.274091 |    352.408373 | Ferran Sayol                                                                                                                                                          |
| 872 |    967.066698 |    315.272555 | T. Michael Keesey                                                                                                                                                     |
| 873 |    674.186894 |    754.305628 | Zimices                                                                                                                                                               |
| 874 |    486.677945 |    467.967930 | Jagged Fang Designs                                                                                                                                                   |
| 875 |    159.643757 |    739.713507 | Gareth Monger                                                                                                                                                         |
| 876 |    472.266559 |    446.357541 | Matt Crook                                                                                                                                                            |
| 877 |     52.682984 |    336.626223 | T. Michael Keesey                                                                                                                                                     |
| 878 |    599.725386 |    248.785775 | \[unknown\]                                                                                                                                                           |
| 879 |    436.051307 |    742.910665 | Zimices                                                                                                                                                               |
| 880 |    593.987402 |    101.291658 | Anthony Caravaggi                                                                                                                                                     |
| 881 |    483.892722 |     21.805028 | Jagged Fang Designs                                                                                                                                                   |
| 882 |    455.246200 |    110.139641 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 883 |    312.642690 |    472.938815 | Scott Hartman                                                                                                                                                         |
| 884 |    159.885122 |    716.775697 | Dean Schnabel                                                                                                                                                         |
| 885 |    244.779267 |    603.484426 | Stuart Humphries                                                                                                                                                      |
| 886 |    197.127413 |    530.107206 | Verdilak                                                                                                                                                              |
| 887 |    795.874394 |    191.856816 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 888 |     98.995854 |    487.470378 | Zimices                                                                                                                                                               |
| 889 |   1013.847667 |    404.357916 | NA                                                                                                                                                                    |
| 890 |    289.251843 |    527.663623 | Eyal Bartov                                                                                                                                                           |
| 891 |     49.272956 |    180.257531 | NA                                                                                                                                                                    |
| 892 |    713.915381 |     70.859472 | Zimices                                                                                                                                                               |
| 893 |    574.614039 |    619.974747 | Matt Martyniuk                                                                                                                                                        |
| 894 |     31.626868 |    324.339638 | Birgit Lang                                                                                                                                                           |
| 895 |    389.055607 |    227.896635 | Sarah Werning                                                                                                                                                         |
| 896 |    128.830796 |    485.205754 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 897 |    185.450207 |    393.409000 | Tracy A. Heath                                                                                                                                                        |
| 898 |     13.213311 |     95.478829 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 899 |    843.741904 |     86.392735 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 900 |    816.498915 |    649.910953 | Jaime Headden                                                                                                                                                         |
| 901 |    395.519492 |    678.507121 | Ignacio Contreras                                                                                                                                                     |
| 902 |    696.146950 |    608.406708 | NA                                                                                                                                                                    |
| 903 |    771.108499 |     50.164629 | Ferran Sayol                                                                                                                                                          |
| 904 |    951.225872 |    606.459101 | T. Michael Keesey                                                                                                                                                     |
| 905 |    534.788737 |    362.099401 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 906 |    257.256625 |    786.750360 | Matt Crook                                                                                                                                                            |
| 907 |   1009.254081 |    732.509181 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 908 |    130.978601 |    617.126182 | C. Camilo Julián-Caballero                                                                                                                                            |
| 909 |     35.632488 |     62.878203 | Beth Reinke                                                                                                                                                           |
| 910 |    433.517556 |    688.828292 | Jake Warner                                                                                                                                                           |
| 911 |    860.660119 |     19.112627 | Christoph Schomburg                                                                                                                                                   |
| 912 |    703.775553 |     35.340097 | Anthony Caravaggi                                                                                                                                                     |
| 913 |    568.353804 |    323.201112 | Kamil S. Jaron                                                                                                                                                        |
| 914 |    369.185458 |    330.548055 | Alexandre Vong                                                                                                                                                        |
| 915 |    858.638891 |    275.749151 | Steven Traver                                                                                                                                                         |
| 916 |    527.508001 |    298.552923 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 917 |    288.986018 |     57.806704 | Zachary Quigley                                                                                                                                                       |
| 918 |    374.631383 |    400.104117 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 919 |    512.730453 |    354.460288 | Matt Crook                                                                                                                                                            |

    #> Your tweet has been posted!
