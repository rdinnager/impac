
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

Zimices, Lauren Sumner-Rooney, Matt Crook, Joe Schneid (vectorized by T.
Michael Keesey), Emma Kissling, Birgit Lang, Taro Maeda, Auckland Museum
and T. Michael Keesey, Gareth Monger, Scott Hartman, Jagged Fang
Designs, Charles R. Knight, vectorized by Zimices, Michael Ströck
(vectorized by T. Michael Keesey), Sergio A. Muñoz-Gómez, Andrew Farke
and Joseph Sertich, Crystal Maier, Michelle Site, FunkMonk, Gabriela
Palomo-Munoz, Mo Hassan, Robbie N. Cada (modified by T. Michael Keesey),
Nobu Tamura (vectorized by T. Michael Keesey), Steven Traver, Melissa
Broussard, Dmitry Bogdanov (vectorized by T. Michael Keesey), T. Michael
Keesey, Filip em, Carlos Cano-Barbacil, Collin Gross, Nobu Tamura
(modified by T. Michael Keesey), Xavier Giroux-Bougard, Sarah Werning,
Martin R. Smith, after Skovsted et al 2015, Ferran Sayol, Tasman Dixon,
Christoph Schomburg, C. Camilo Julián-Caballero, Scott Hartman, modified
by T. Michael Keesey, CNZdenek, Chris A. Hamilton, Margot Michaud, Lani
Mohan, H. Filhol (vectorized by T. Michael Keesey), Maxime Dahirel,
Frank Förster, Chris huh, Iain Reid, Michael Scroggie, Neil Kelley,
nicubunu, RS, Rebecca Groom, Kelly, Joanna Wolfe, Jack Mayer Wood,
Smokeybjb, Trond R. Oskars, Milton Tan, Yan Wong, Steven Coombs, NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), T. Michael Keesey (vectorization); Thorsten
Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal
Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography),
Beth Reinke, Dean Schnabel, Jon Hill, Jan A. Venter, Herbert H. T.
Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Zachary Quigley, Ghedoghedo (vectorized by T. Michael Keesey), Mali’o
Kodis, photograph from Jersabek et al, 2003, David Orr, Matt Martyniuk,
Liftarn, Dmitry Bogdanov, Juan Carlos Jerí, wsnaccad, Archaeodontosaurus
(vectorized by T. Michael Keesey), Kamil S. Jaron, Noah Schlottman,
Amanda Katzer, Mark Hannaford (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Emily Willoughby, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Ben Liebeskind, Alex Slavenko, Tauana J. Cunha, Joedison Rocha,
Robbie N. Cada (vectorized by T. Michael Keesey), Bennet McComish, photo
by Hans Hillewaert, Stemonitis (photography) and T. Michael Keesey
(vectorization), Kai R. Caspar, J Levin W (illustration) and T. Michael
Keesey (vectorization), James R. Spotila and Ray Chatterji, Andreas
Trepte (vectorized by T. Michael Keesey), Jordan Mallon (vectorized by
T. Michael Keesey), Lukasiniho, xgirouxb, Scott Reid, Philippe Janvier
(vectorized by T. Michael Keesey), Felix Vaux, L. Shyamal, Antonov
(vectorized by T. Michael Keesey), Mali’o Kodis, image by Rebecca
Ritger, T. Michael Keesey (after James & al.), Maxime Dahirel
(digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Andrew A. Farke, DW Bapst
(modified from Mitchell 1990), Shyamal, Maija Karala, Matthew E.
Clapham, Kosta Mumcuoglu (vectorized by T. Michael Keesey), Chloé
Schmidt, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf
Jondelius (vectorized by T. Michael Keesey), Jon M Laurent, Kailah Thorn
& Mark Hutchinson, Tracy A. Heath, Maxwell Lefroy (vectorized by T.
Michael Keesey), Obsidian Soul (vectorized by T. Michael Keesey),
Jonathan Wells, Maky (vectorization), Gabriella Skollar (photography),
Rebecca Lewis (editing), Pollyanna von Knorring and T. Michael Keesey,
Margret Flinsch, vectorized by Zimices, Sean McCann, Adrian Reich,
Renato Santos, Steven Haddock • Jellywatch.org, M Kolmann, Dmitry
Bogdanov and FunkMonk (vectorized by T. Michael Keesey), Emma Hughes,
George Edward Lodge (modified by T. Michael Keesey), Jose Carlos
Arenas-Monroy, Sam Fraser-Smith (vectorized by T. Michael Keesey), Oscar
Sanisidro, Taenadoman, Mariana Ruiz Villarreal (modified by T. Michael
Keesey), Smith609 and T. Michael Keesey, Nobu Tamura (vectorized by A.
Verrière), Emil Schmidt (vectorized by Maxime Dahirel), DW Bapst
(modified from Bulman, 1970), Yan Wong from photo by Denes Emoke, Harold
N Eyster, (after Spotila 2004), Paul O. Lewis, Stacy Spensley
(Modified), Karl Ragnar Gjertsen (vectorized by T. Michael Keesey), Ryan
Cupo, Zimices / Julián Bayona, Geoff Shaw, FJDegrange, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Robert Gay, T.
Michael Keesey (after Mivart), NASA, Dave Souza (vectorized by T.
Michael Keesey), Samanta Orellana, Stanton F. Fink (vectorized by T.
Michael Keesey), Gabriel Lio, vectorized by Zimices, Mathilde
Cordellier, Anthony Caravaggi, Jesús Gómez, vectorized by Zimices,
Mali’o Kodis, photograph by Hans Hillewaert, Julio Garza, Katie S.
Collins, Chase Brownstein, Darren Naish (vectorized by T. Michael
Keesey), Frederick William Frohawk (vectorized by T. Michael Keesey),
Rachel Shoop, Noah Schlottman, photo from Casey Dunn, Roger Witter,
vectorized by Zimices, Smokeybjb, vectorized by Zimices, Noah
Schlottman, photo by Martin V. Sørensen, Ralf Janssen, Nikola-Michael
Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey), Pearson Scott
Foresman (vectorized by T. Michael Keesey), Gopal Murali, Evan-Amos
(vectorized by T. Michael Keesey), Meyer-Wachsmuth I, Curini Galletti M,
Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y.
Wong, Caleb M. Gordon, Matt Wilkins, Jiekun He, Notafly (vectorized by
T. Michael Keesey), Martin R. Smith, Kailah Thorn & Ben King, Jim Bendon
(photography) and T. Michael Keesey (vectorization), Michele Tobias,
Mason McNair, Caleb M. Brown, Mathieu Basille, Mary Harrsch (modified by
T. Michael Keesey), FunkMonk (Michael B. H.), Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Jaime
Headden, Christine Axon, Pete Buchholz, Ville-Veikko Sinkkonen, Ron
Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Yan Wong from wikipedia drawing (PD: Pearson Scott
Foresman), Nobu Tamura, vectorized by Zimices, terngirl, Alexandra van
der Geer, Birgit Lang; original image by virmisco.org, Matt Dempsey,
Noah Schlottman, photo by Casey Dunn, Roberto Díaz Sibaja, Becky Barnes,
Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Cesar Julian,
Alexander Schmidt-Lebuhn, Aadx, Darren Naish (vectorize by T. Michael
Keesey), Ghedo (vectorized by T. Michael Keesey), Alexandre Vong, Mykle
Hoban, Philip Chalmers (vectorized by T. Michael Keesey), Y. de Hoev.
(vectorized by T. Michael Keesey), Rainer Schoch, Ingo Braasch, Noah
Schlottman, photo by Museum of Geology, University of Tartu,
SecretJellyMan, T. Michael Keesey (after Heinrich Harder), Javier Luque,
George Edward Lodge (vectorized by T. Michael Keesey), Francisco Gascó
(modified by Michael P. Taylor), Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Mattia
Menchetti, Lauren Anderson, Jake Warner, Douglas Brown (modified by T.
Michael Keesey), LeonardoG (photography) and T. Michael Keesey
(vectorization), T. Michael Keesey (from a mount by Allis Markham),
Sharon Wegner-Larsen, Caio Bernardes, vectorized by Zimices, Francis de
Laporte de Castelnau (vectorized by T. Michael Keesey), Sherman F.
Denton via rawpixel.com (illustration) and Timothy J. Bartley
(silhouette), Darius Nau, Mali’o Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Brad McFeeters
(vectorized by T. Michael Keesey), Lukas Panzarin, Dianne Bray / Museum
Victoria (vectorized by T. Michael Keesey), Birgit Lang; based on a
drawing by C.L. Koch, Matt Martyniuk (modified by T. Michael Keesey),
Tomas Willems (vectorized by T. Michael Keesey), Enoch Joseph Wetsy
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), M Hutchinson, S.Martini, Alyssa Bell &
Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690, Noah
Schlottman, photo from National Science Foundation - Turbellarian
Taxonomic Database, Didier Descouens (vectorized by T. Michael Keesey),
Jessica Anne Miller, Zsoldos Márton (vectorized by T. Michael Keesey),
Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist,
Mathew Wedel, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy
J. Bartley (silhouette), Ewald Rübsamen, Noah Schlottman, photo by Adam
G. Clause, Ray Simpson (vectorized by T. Michael Keesey), Richard
Lampitt, Jeremy Young / NHM (vectorization by Yan Wong), Tim Bertelink
(modified by T. Michael Keesey), Mali’o Kodis, traced image from the
National Science Foundation’s Turbellarian Taxonomic Database, Oren
Peles / vectorized by Yan Wong, Manabu Bessho-Uehara, Dmitry Bogdanov,
vectorized by Zimices, www.studiospectre.com, Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, Michele M Tobias from an
image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, H. F. O.
March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J.
Wedel), Peileppe, Smokeybjb (vectorized by T. Michael Keesey), Cagri
Cevrim, Auckland Museum, Falconaumanni and T. Michael Keesey, Lily
Hughes, Armin Reindl, Arthur S. Brum, Inessa Voet, Mali’o Kodis, image
from the “Proceedings of the Zoological Society of London”

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    686.661666 |    416.502020 | Zimices                                                                                                                                                                              |
|   2 |    297.671786 |    751.359487 | Lauren Sumner-Rooney                                                                                                                                                                 |
|   3 |    557.692481 |    707.529050 | Matt Crook                                                                                                                                                                           |
|   4 |    540.860654 |    130.089157 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                        |
|   5 |    745.066922 |     45.863240 | Emma Kissling                                                                                                                                                                        |
|   6 |    242.696996 |     77.590357 | Birgit Lang                                                                                                                                                                          |
|   7 |    243.725304 |    616.800135 | Zimices                                                                                                                                                                              |
|   8 |    864.694811 |    205.579600 | NA                                                                                                                                                                                   |
|   9 |    179.096205 |    270.829800 | Taro Maeda                                                                                                                                                                           |
|  10 |    142.885403 |    451.909941 | Auckland Museum and T. Michael Keesey                                                                                                                                                |
|  11 |    422.770518 |    116.198762 | Gareth Monger                                                                                                                                                                        |
|  12 |    765.265258 |    609.257829 | Zimices                                                                                                                                                                              |
|  13 |    170.775387 |    334.957248 | Scott Hartman                                                                                                                                                                        |
|  14 |    436.560020 |    462.808326 | Jagged Fang Designs                                                                                                                                                                  |
|  15 |    935.992144 |    576.697534 | Charles R. Knight, vectorized by Zimices                                                                                                                                             |
|  16 |    829.587492 |    673.605227 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                                     |
|  17 |    928.307430 |    470.079105 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
|  18 |    773.658149 |    265.331051 | Andrew Farke and Joseph Sertich                                                                                                                                                      |
|  19 |    695.102438 |    137.212108 | Crystal Maier                                                                                                                                                                        |
|  20 |    577.257626 |    541.801634 | Michelle Site                                                                                                                                                                        |
|  21 |    629.179766 |    199.545498 | FunkMonk                                                                                                                                                                             |
|  22 |    349.587618 |    291.082973 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  23 |    947.454907 |    138.892897 | Zimices                                                                                                                                                                              |
|  24 |    541.280680 |    605.552210 | Mo Hassan                                                                                                                                                                            |
|  25 |    442.220749 |    414.975798 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
|  26 |     82.741463 |    748.152208 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  27 |    131.531213 |    176.309339 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  28 |    788.736338 |    106.422511 | Steven Traver                                                                                                                                                                        |
|  29 |    511.619528 |     41.930094 | Melissa Broussard                                                                                                                                                                    |
|  30 |    100.929932 |     88.163891 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  31 |    931.155900 |    262.027022 | T. Michael Keesey                                                                                                                                                                    |
|  32 |    357.190068 |    484.710083 | Filip em                                                                                                                                                                             |
|  33 |    484.464287 |    278.713812 | Carlos Cano-Barbacil                                                                                                                                                                 |
|  34 |    591.262548 |    431.558782 | Collin Gross                                                                                                                                                                         |
|  35 |    640.517029 |    747.186052 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
|  36 |    918.188738 |    643.942350 | Xavier Giroux-Bougard                                                                                                                                                                |
|  37 |    750.160166 |     18.365252 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  38 |    940.016196 |     60.866232 | Steven Traver                                                                                                                                                                        |
|  39 |    281.479106 |    176.924553 | Michelle Site                                                                                                                                                                        |
|  40 |    746.388954 |    514.793942 | Gareth Monger                                                                                                                                                                        |
|  41 |    858.986158 |    754.527612 | Sarah Werning                                                                                                                                                                        |
|  42 |    110.882418 |    661.898679 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                           |
|  43 |    288.792761 |    385.991260 | Ferran Sayol                                                                                                                                                                         |
|  44 |    961.644685 |    713.104184 | T. Michael Keesey                                                                                                                                                                    |
|  45 |    614.804514 |     81.682325 | Ferran Sayol                                                                                                                                                                         |
|  46 |    229.869524 |    500.685363 | Tasman Dixon                                                                                                                                                                         |
|  47 |    683.554602 |    676.291721 | Christoph Schomburg                                                                                                                                                                  |
|  48 |     92.892849 |    384.312315 | Scott Hartman                                                                                                                                                                        |
|  49 |    897.050277 |    544.065072 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  50 |    430.991864 |    364.370645 | Scott Hartman, modified by T. Michael Keesey                                                                                                                                         |
|  51 |    630.006991 |    248.883972 | CNZdenek                                                                                                                                                                             |
|  52 |    962.813918 |    380.586167 | Chris A. Hamilton                                                                                                                                                                    |
|  53 |     92.914818 |     41.539959 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  54 |    451.790143 |    710.735600 | Margot Michaud                                                                                                                                                                       |
|  55 |     65.563180 |    274.275400 | Crystal Maier                                                                                                                                                                        |
|  56 |    983.249209 |    269.388020 | T. Michael Keesey                                                                                                                                                                    |
|  57 |    463.130289 |    557.313763 | Gareth Monger                                                                                                                                                                        |
|  58 |    494.998129 |    779.182802 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  59 |     45.981100 |    660.563322 | Lani Mohan                                                                                                                                                                           |
|  60 |    483.592405 |    655.714765 | Scott Hartman                                                                                                                                                                        |
|  61 |    758.025811 |    761.090543 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                                          |
|  62 |    342.891379 |     81.822577 | Maxime Dahirel                                                                                                                                                                       |
|  63 |    122.163676 |    131.014356 | Frank Förster                                                                                                                                                                        |
|  64 |    675.295922 |    605.204824 | Chris huh                                                                                                                                                                            |
|  65 |    285.727446 |    449.646514 | Iain Reid                                                                                                                                                                            |
|  66 |    669.966064 |    549.746320 | Michael Scroggie                                                                                                                                                                     |
|  67 |    377.668919 |    754.415184 | Neil Kelley                                                                                                                                                                          |
|  68 |   1000.231489 |    604.157345 | Ferran Sayol                                                                                                                                                                         |
|  69 |    965.189856 |    193.618421 | nicubunu                                                                                                                                                                             |
|  70 |    351.298303 |    171.057724 | Matt Crook                                                                                                                                                                           |
|  71 |    420.556404 |    296.046626 | Scott Hartman                                                                                                                                                                        |
|  72 |     71.873484 |    201.401526 | RS                                                                                                                                                                                   |
|  73 |     21.941132 |    150.751828 | Jagged Fang Designs                                                                                                                                                                  |
|  74 |    377.146775 |    438.206527 | Rebecca Groom                                                                                                                                                                        |
|  75 |    829.408991 |    561.751660 | Kelly                                                                                                                                                                                |
|  76 |    364.571209 |    206.250207 | Joanna Wolfe                                                                                                                                                                         |
|  77 |     35.437693 |    585.884136 | Matt Crook                                                                                                                                                                           |
|  78 |    208.825367 |    402.105203 | Crystal Maier                                                                                                                                                                        |
|  79 |    173.333569 |    733.933204 | Steven Traver                                                                                                                                                                        |
|  80 |     22.323496 |    559.455207 | Jack Mayer Wood                                                                                                                                                                      |
|  81 |    163.557475 |     16.571149 | NA                                                                                                                                                                                   |
|  82 |    758.694847 |    705.418605 | NA                                                                                                                                                                                   |
|  83 |    464.277412 |    618.847879 | Smokeybjb                                                                                                                                                                            |
|  84 |    249.428325 |    243.197890 | Trond R. Oskars                                                                                                                                                                      |
|  85 |    183.846334 |    781.230885 | Milton Tan                                                                                                                                                                           |
|  86 |    154.599865 |    406.961947 | Yan Wong                                                                                                                                                                             |
|  87 |    498.606409 |    314.429363 | Steven Coombs                                                                                                                                                                        |
|  88 |    481.139532 |    369.488225 | Zimices                                                                                                                                                                              |
|  89 |    749.962385 |    115.275335 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                                |
|  90 |    570.115893 |     37.578405 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
|  91 |    843.252841 |    614.567128 | Steven Traver                                                                                                                                                                        |
|  92 |     48.378352 |    169.295285 | NA                                                                                                                                                                                   |
|  93 |    973.092910 |    482.120328 | Beth Reinke                                                                                                                                                                          |
|  94 |    141.901858 |    722.620720 | Dean Schnabel                                                                                                                                                                        |
|  95 |    520.809876 |    206.685225 | Matt Crook                                                                                                                                                                           |
|  96 |    145.027816 |    208.312718 | Jon Hill                                                                                                                                                                             |
|  97 |    428.913259 |    232.321557 | Margot Michaud                                                                                                                                                                       |
|  98 |    296.703533 |    325.887838 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|  99 |    978.396384 |    630.633206 | Zachary Quigley                                                                                                                                                                      |
| 100 |   1008.136239 |     17.940771 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 101 |    867.239562 |     75.849697 | Melissa Broussard                                                                                                                                                                    |
| 102 |    506.507554 |    539.206907 | Birgit Lang                                                                                                                                                                          |
| 103 |    544.641449 |    208.868343 | Jagged Fang Designs                                                                                                                                                                  |
| 104 |   1000.417808 |    192.730244 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                                   |
| 105 |    350.147140 |    242.216758 | Chris huh                                                                                                                                                                            |
| 106 |     79.369219 |    485.309037 | T. Michael Keesey                                                                                                                                                                    |
| 107 |    885.404606 |    315.394599 | David Orr                                                                                                                                                                            |
| 108 |    327.161094 |    698.483461 | Zimices                                                                                                                                                                              |
| 109 |    568.253148 |    297.871743 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 110 |    544.102665 |    554.984909 | Matt Martyniuk                                                                                                                                                                       |
| 111 |    341.903741 |    426.075031 | Steven Traver                                                                                                                                                                        |
| 112 |    171.990169 |    369.517144 | Steven Traver                                                                                                                                                                        |
| 113 |     54.461609 |    333.651923 | Liftarn                                                                                                                                                                              |
| 114 |    691.148224 |     73.241252 | Dmitry Bogdanov                                                                                                                                                                      |
| 115 |    245.787104 |    417.790992 | Chris huh                                                                                                                                                                            |
| 116 |    699.193490 |    286.525318 | Scott Hartman                                                                                                                                                                        |
| 117 |    154.498776 |    103.122657 | Dean Schnabel                                                                                                                                                                        |
| 118 |    268.885838 |     33.408988 | Juan Carlos Jerí                                                                                                                                                                     |
| 119 |    926.451587 |    339.366839 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 120 |    879.985319 |    443.877773 | wsnaccad                                                                                                                                                                             |
| 121 |    874.661850 |    501.366497 | Margot Michaud                                                                                                                                                                       |
| 122 |    406.780249 |    741.249423 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 123 |    574.343325 |    275.532421 | Kamil S. Jaron                                                                                                                                                                       |
| 124 |    849.952089 |     66.552157 | Matt Crook                                                                                                                                                                           |
| 125 |     18.588628 |     64.139287 | T. Michael Keesey                                                                                                                                                                    |
| 126 |    559.938489 |    230.685187 | Noah Schlottman                                                                                                                                                                      |
| 127 |    648.033533 |    277.625153 | Gareth Monger                                                                                                                                                                        |
| 128 |    421.814171 |    669.151852 | Zimices                                                                                                                                                                              |
| 129 |    192.359122 |    347.996479 | Amanda Katzer                                                                                                                                                                        |
| 130 |    812.252899 |    281.726257 | Chris huh                                                                                                                                                                            |
| 131 |    472.417510 |    219.565865 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                       |
| 132 |    345.242454 |    513.056565 | Emily Willoughby                                                                                                                                                                     |
| 133 |     57.645377 |    688.593067 | Rebecca Groom                                                                                                                                                                        |
| 134 |    315.337667 |    677.511362 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 135 |    796.848299 |    711.106027 | Zimices                                                                                                                                                                              |
| 136 |    591.309223 |    125.644807 | Ben Liebeskind                                                                                                                                                                       |
| 137 |    640.388293 |    483.373365 | Zimices                                                                                                                                                                              |
| 138 |    725.153496 |    564.679233 | NA                                                                                                                                                                                   |
| 139 |    594.658372 |    292.515611 | Alex Slavenko                                                                                                                                                                        |
| 140 |    448.447134 |     35.756050 | Zimices                                                                                                                                                                              |
| 141 |    578.889443 |    529.860973 | Matt Crook                                                                                                                                                                           |
| 142 |    981.586114 |    528.667484 | Tauana J. Cunha                                                                                                                                                                      |
| 143 |    634.937418 |    597.667751 | Gareth Monger                                                                                                                                                                        |
| 144 |    609.419939 |     25.324721 | Joedison Rocha                                                                                                                                                                       |
| 145 |    774.695617 |    212.596278 | Jagged Fang Designs                                                                                                                                                                  |
| 146 |    465.833719 |    117.104771 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 147 |    739.189455 |    278.960851 | Bennet McComish, photo by Hans Hillewaert                                                                                                                                            |
| 148 |     51.037079 |    424.796560 | Iain Reid                                                                                                                                                                            |
| 149 |    886.042305 |    527.625261 | Jagged Fang Designs                                                                                                                                                                  |
| 150 |    867.058014 |    105.869201 | NA                                                                                                                                                                                   |
| 151 |    894.933813 |    104.095651 | T. Michael Keesey                                                                                                                                                                    |
| 152 |    854.925994 |    590.029278 | Margot Michaud                                                                                                                                                                       |
| 153 |    201.708362 |     23.464440 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 154 |    707.879851 |    199.365518 | Kai R. Caspar                                                                                                                                                                        |
| 155 |    502.809529 |    202.154525 | NA                                                                                                                                                                                   |
| 156 |    623.442224 |    493.082412 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                                       |
| 157 |    575.051981 |    663.884576 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 158 |     34.113166 |    480.152709 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 159 |    957.812660 |    793.903603 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 160 |    303.329033 |     17.547001 | NA                                                                                                                                                                                   |
| 161 |     45.579939 |    610.992096 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                     |
| 162 |    139.371460 |    624.798911 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                                      |
| 163 |    484.110748 |    175.024081 | Lukasiniho                                                                                                                                                                           |
| 164 |    664.307597 |     16.659912 | Zimices                                                                                                                                                                              |
| 165 |    941.720408 |    389.375823 | Steven Coombs                                                                                                                                                                        |
| 166 |    922.753672 |    171.540870 | xgirouxb                                                                                                                                                                             |
| 167 |    961.971127 |    177.625845 | Matt Crook                                                                                                                                                                           |
| 168 |    273.020434 |    281.181402 | Scott Reid                                                                                                                                                                           |
| 169 |    388.289321 |     37.797046 | Beth Reinke                                                                                                                                                                          |
| 170 |    207.615398 |    144.049891 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                                   |
| 171 |    220.095581 |    754.988302 | Felix Vaux                                                                                                                                                                           |
| 172 |    884.504874 |    364.088346 | Michael Scroggie                                                                                                                                                                     |
| 173 |    703.038863 |    714.296721 | L. Shyamal                                                                                                                                                                           |
| 174 |    484.904189 |    123.777959 | NA                                                                                                                                                                                   |
| 175 |    385.975502 |    539.861180 | Zimices                                                                                                                                                                              |
| 176 |    981.694863 |    452.351105 | NA                                                                                                                                                                                   |
| 177 |    968.945186 |    561.912819 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
| 178 |    506.307300 |    433.775656 | Michelle Site                                                                                                                                                                        |
| 179 |    807.219336 |    232.767941 | NA                                                                                                                                                                                   |
| 180 |   1009.730845 |    466.512580 | Margot Michaud                                                                                                                                                                       |
| 181 |   1008.608600 |    434.836961 | NA                                                                                                                                                                                   |
| 182 |    567.120211 |    544.195712 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                                |
| 183 |    775.758733 |    571.348720 | NA                                                                                                                                                                                   |
| 184 |    157.799538 |    680.838533 | T. Michael Keesey (after James & al.)                                                                                                                                                |
| 185 |    732.498606 |    199.637444 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                                           |
| 186 |    964.255023 |    339.818968 | Margot Michaud                                                                                                                                                                       |
| 187 |    878.084284 |    779.851964 | Andrew A. Farke                                                                                                                                                                      |
| 188 |     14.571868 |    518.249210 | DW Bapst (modified from Mitchell 1990)                                                                                                                                               |
| 189 |    928.317308 |    417.037290 | Shyamal                                                                                                                                                                              |
| 190 |     82.088764 |     18.965384 | Maija Karala                                                                                                                                                                         |
| 191 |    497.650856 |     87.500255 | Margot Michaud                                                                                                                                                                       |
| 192 |    255.814847 |     13.437091 | Matthew E. Clapham                                                                                                                                                                   |
| 193 |    313.801522 |    342.977233 | Michelle Site                                                                                                                                                                        |
| 194 |    883.704111 |    664.185040 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 195 |    215.606617 |    122.247235 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 196 |     64.139746 |    604.749845 | Dmitry Bogdanov                                                                                                                                                                      |
| 197 |    642.038812 |    176.078462 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                                    |
| 198 |    783.246271 |    448.593937 | Margot Michaud                                                                                                                                                                       |
| 199 |    612.318433 |    624.814301 | Chloé Schmidt                                                                                                                                                                        |
| 200 |    679.011475 |     53.614843 | Melissa Broussard                                                                                                                                                                    |
| 201 |     17.440333 |    372.138903 | Ferran Sayol                                                                                                                                                                         |
| 202 |    275.969232 |    707.781627 | NA                                                                                                                                                                                   |
| 203 |    254.032582 |    699.111643 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                                             |
| 204 |    832.894469 |    241.776790 | Jon M Laurent                                                                                                                                                                        |
| 205 |    143.915685 |     53.201935 | Chris huh                                                                                                                                                                            |
| 206 |    974.111810 |    666.109931 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 207 |     61.405135 |    144.525471 | Margot Michaud                                                                                                                                                                       |
| 208 |    857.807576 |    285.616663 | Margot Michaud                                                                                                                                                                       |
| 209 |    629.522176 |    107.670010 | Kamil S. Jaron                                                                                                                                                                       |
| 210 |    631.340565 |     23.342269 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 211 |    438.052779 |    496.852301 | Tracy A. Heath                                                                                                                                                                       |
| 212 |    872.600244 |    329.838005 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 213 |    378.994296 |    515.733117 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 214 |    584.893224 |    759.761115 | Matt Martyniuk                                                                                                                                                                       |
| 215 |    201.433484 |    463.639539 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 216 |    768.917073 |    170.860427 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 217 |    878.278745 |    139.990021 | Gareth Monger                                                                                                                                                                        |
| 218 |     78.604832 |    216.068626 | Jagged Fang Designs                                                                                                                                                                  |
| 219 |    473.804111 |    319.150927 | Jonathan Wells                                                                                                                                                                       |
| 220 |   1015.367691 |    756.281882 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 221 |     26.223505 |    540.995470 | Birgit Lang                                                                                                                                                                          |
| 222 |     11.157770 |    652.091427 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                       |
| 223 |     24.816094 |    637.091595 | Zimices                                                                                                                                                                              |
| 224 |    282.195769 |    684.715343 | Tauana J. Cunha                                                                                                                                                                      |
| 225 |    508.489657 |    116.327136 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                         |
| 226 |    959.697115 |    492.730987 | Sarah Werning                                                                                                                                                                        |
| 227 |    128.119925 |    352.207850 | Sarah Werning                                                                                                                                                                        |
| 228 |    939.685303 |    755.076952 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 229 |   1013.058506 |    532.873234 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 230 |    995.067471 |    358.342000 | RS                                                                                                                                                                                   |
| 231 |    782.071327 |    301.326761 | Tasman Dixon                                                                                                                                                                         |
| 232 |    796.309207 |    158.085555 | Ferran Sayol                                                                                                                                                                         |
| 233 |    789.962234 |     24.117687 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 234 |    808.191328 |    558.627548 | Zimices                                                                                                                                                                              |
| 235 |    245.100588 |    741.632538 | Felix Vaux                                                                                                                                                                           |
| 236 |    665.162709 |    565.137938 | Margret Flinsch, vectorized by Zimices                                                                                                                                               |
| 237 |    296.945065 |    240.161904 | Scott Hartman                                                                                                                                                                        |
| 238 |    237.854886 |    372.220422 | Michael Scroggie                                                                                                                                                                     |
| 239 |    912.531904 |    434.256514 | Sean McCann                                                                                                                                                                          |
| 240 |    487.933562 |     74.363471 | Adrian Reich                                                                                                                                                                         |
| 241 |   1006.640971 |     51.185405 | Renato Santos                                                                                                                                                                        |
| 242 |   1015.320059 |    143.068777 | Jack Mayer Wood                                                                                                                                                                      |
| 243 |    914.255878 |    460.937412 | NA                                                                                                                                                                                   |
| 244 |   1012.495815 |    440.715705 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 245 |      9.345245 |    600.036816 | Tauana J. Cunha                                                                                                                                                                      |
| 246 |     31.990664 |    108.090234 | Matt Crook                                                                                                                                                                           |
| 247 |    638.300382 |     10.798123 | Margot Michaud                                                                                                                                                                       |
| 248 |    381.270667 |    148.706504 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 249 |    356.300501 |    378.701783 | M Kolmann                                                                                                                                                                            |
| 250 |    835.534726 |    305.777164 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                                       |
| 251 |    475.135961 |     86.940542 | Michelle Site                                                                                                                                                                        |
| 252 |    617.046958 |    716.884687 | Dmitry Bogdanov                                                                                                                                                                      |
| 253 |    349.482106 |    402.258314 | Scott Reid                                                                                                                                                                           |
| 254 |      7.858098 |    444.052409 | Scott Hartman                                                                                                                                                                        |
| 255 |    458.752528 |    627.801236 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 256 |    985.660209 |    617.203491 | Zimices                                                                                                                                                                              |
| 257 |    928.718644 |    785.850112 | Emma Hughes                                                                                                                                                                          |
| 258 |    444.653763 |    327.879283 | NA                                                                                                                                                                                   |
| 259 |    726.625306 |    234.086440 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                                  |
| 260 |    888.168343 |    242.725569 | Milton Tan                                                                                                                                                                           |
| 261 |    277.702907 |    314.686491 | Steven Traver                                                                                                                                                                        |
| 262 |    115.577704 |    158.196271 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 263 |    983.047568 |    769.568566 | Margot Michaud                                                                                                                                                                       |
| 264 |    862.124364 |     50.599580 | Tracy A. Heath                                                                                                                                                                       |
| 265 |    772.423708 |    227.233247 | Matt Crook                                                                                                                                                                           |
| 266 |    520.198100 |    448.750496 | NA                                                                                                                                                                                   |
| 267 |    819.079510 |    250.278569 | Zimices                                                                                                                                                                              |
| 268 |    792.011424 |    291.673311 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                                   |
| 269 |    819.810185 |    138.906369 | Beth Reinke                                                                                                                                                                          |
| 270 |    929.907718 |    532.615216 | Oscar Sanisidro                                                                                                                                                                      |
| 271 |    986.328053 |    782.602489 | Taenadoman                                                                                                                                                                           |
| 272 |    641.006902 |    157.188020 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                                              |
| 273 |     13.217697 |     99.255342 | Birgit Lang                                                                                                                                                                          |
| 274 |    878.133894 |     25.972137 | Chris huh                                                                                                                                                                            |
| 275 |   1004.318897 |    225.427076 | xgirouxb                                                                                                                                                                             |
| 276 |    477.571040 |    381.576519 | Smith609 and T. Michael Keesey                                                                                                                                                       |
| 277 |    870.801865 |    602.168422 | T. Michael Keesey                                                                                                                                                                    |
| 278 |    381.279724 |    448.046549 | Matt Crook                                                                                                                                                                           |
| 279 |    744.750898 |    151.817610 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 280 |    154.154010 |    768.571432 | Ferran Sayol                                                                                                                                                                         |
| 281 |    105.568598 |    351.352174 | Jonathan Wells                                                                                                                                                                       |
| 282 |    157.550590 |     57.554062 | Zimices                                                                                                                                                                              |
| 283 |   1016.124448 |    585.372821 | Gareth Monger                                                                                                                                                                        |
| 284 |    526.980918 |    523.037337 | Steven Traver                                                                                                                                                                        |
| 285 |    685.301363 |    764.937646 | Matt Crook                                                                                                                                                                           |
| 286 |    539.601872 |    461.137888 | Ferran Sayol                                                                                                                                                                         |
| 287 |    522.761264 |    658.279377 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 288 |    243.900518 |    296.379429 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                          |
| 289 |    666.823309 |    774.885643 | Beth Reinke                                                                                                                                                                          |
| 290 |    765.369170 |    641.564724 | Scott Hartman                                                                                                                                                                        |
| 291 |    568.793484 |     69.433347 | Scott Hartman                                                                                                                                                                        |
| 292 |    876.905936 |    468.767528 | Scott Reid                                                                                                                                                                           |
| 293 |    858.242439 |    423.479368 | DW Bapst (modified from Bulman, 1970)                                                                                                                                                |
| 294 |    750.099062 |    179.094123 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
| 295 |    342.402082 |    720.701622 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 296 |    471.038995 |    159.244359 | Zimices                                                                                                                                                                              |
| 297 |    273.747336 |    479.911339 | Tracy A. Heath                                                                                                                                                                       |
| 298 |    807.767919 |    578.114399 | Matt Crook                                                                                                                                                                           |
| 299 |     21.295624 |    325.213952 | T. Michael Keesey                                                                                                                                                                    |
| 300 |    503.800206 |    490.549900 | Birgit Lang                                                                                                                                                                          |
| 301 |    246.931515 |    219.980736 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 302 |    561.520513 |     60.260055 | NA                                                                                                                                                                                   |
| 303 |    523.099828 |    263.938721 | Kamil S. Jaron                                                                                                                                                                       |
| 304 |   1012.953989 |    519.573255 | Harold N Eyster                                                                                                                                                                      |
| 305 |    621.249111 |    789.808342 | Steven Traver                                                                                                                                                                        |
| 306 |    978.942903 |    165.040926 | (after Spotila 2004)                                                                                                                                                                 |
| 307 |    733.956728 |    102.059719 | Margot Michaud                                                                                                                                                                       |
| 308 |    126.061495 |    311.579904 | Paul O. Lewis                                                                                                                                                                        |
| 309 |    908.458611 |    420.211936 | Stacy Spensley (Modified)                                                                                                                                                            |
| 310 |    219.250889 |    322.781761 | NA                                                                                                                                                                                   |
| 311 |    309.895130 |    785.121356 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                        |
| 312 |    551.568287 |    675.231674 | Andrew A. Farke                                                                                                                                                                      |
| 313 |    626.203809 |    637.563412 | Gareth Monger                                                                                                                                                                        |
| 314 |     30.364899 |    198.010324 | Gareth Monger                                                                                                                                                                        |
| 315 |    918.579429 |    370.448582 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                               |
| 316 |    927.980690 |    183.230352 | Scott Hartman                                                                                                                                                                        |
| 317 |    255.689081 |    723.754560 | Beth Reinke                                                                                                                                                                          |
| 318 |    360.632996 |    448.975770 | Ryan Cupo                                                                                                                                                                            |
| 319 |    183.151841 |    468.389535 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 320 |    560.311645 |    194.836346 | Joanna Wolfe                                                                                                                                                                         |
| 321 |    584.267814 |    449.880174 | NA                                                                                                                                                                                   |
| 322 |    812.858740 |     31.437338 | NA                                                                                                                                                                                   |
| 323 |    950.147968 |    519.471639 | Dean Schnabel                                                                                                                                                                        |
| 324 |     46.928847 |    212.718782 | Gareth Monger                                                                                                                                                                        |
| 325 |    580.098638 |    676.451292 | Zimices / Julián Bayona                                                                                                                                                              |
| 326 |    109.254790 |    457.316794 | Zimices                                                                                                                                                                              |
| 327 |     60.016725 |    715.781505 | Geoff Shaw                                                                                                                                                                           |
| 328 |    284.018671 |    144.633628 | FJDegrange                                                                                                                                                                           |
| 329 |    210.151462 |    537.271741 | Matt Crook                                                                                                                                                                           |
| 330 |    685.984588 |     22.244743 | Melissa Broussard                                                                                                                                                                    |
| 331 |     95.118667 |    340.575153 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
| 332 |      7.688543 |    377.515220 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 333 |      8.820569 |    569.613597 | Michelle Site                                                                                                                                                                        |
| 334 |     17.470368 |    454.533178 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 335 |    648.272463 |    591.087614 | Christoph Schomburg                                                                                                                                                                  |
| 336 |    815.956380 |    211.831996 | Chris huh                                                                                                                                                                            |
| 337 |    656.280282 |    624.860325 | Lukasiniho                                                                                                                                                                           |
| 338 |    527.930495 |    306.524746 | Robert Gay                                                                                                                                                                           |
| 339 |    541.918775 |    221.227336 | Dean Schnabel                                                                                                                                                                        |
| 340 |    373.210617 |     14.252883 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 341 |    296.805373 |    127.518370 | NASA                                                                                                                                                                                 |
| 342 |     48.008769 |      8.589510 | Collin Gross                                                                                                                                                                         |
| 343 |    952.352235 |     93.022484 | Collin Gross                                                                                                                                                                         |
| 344 |    109.199579 |    585.634770 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 345 |    175.474025 |     56.738714 | Matt Crook                                                                                                                                                                           |
| 346 |    671.784215 |    629.287794 | Birgit Lang                                                                                                                                                                          |
| 347 |    308.336809 |    451.535851 | Chris huh                                                                                                                                                                            |
| 348 |    636.199128 |    556.299170 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 349 |    738.769197 |    297.925783 | Andrew A. Farke                                                                                                                                                                      |
| 350 |    389.374151 |    766.855195 | Matt Crook                                                                                                                                                                           |
| 351 |    699.371929 |    302.448665 | Matt Crook                                                                                                                                                                           |
| 352 |    520.187368 |    461.347175 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 353 |    262.445640 |    162.238762 | Margot Michaud                                                                                                                                                                       |
| 354 |    649.292916 |    442.539575 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 355 |    584.717592 |    108.750622 | Taro Maeda                                                                                                                                                                           |
| 356 |    951.538865 |    229.694019 | Samanta Orellana                                                                                                                                                                     |
| 357 |     92.543272 |    154.896844 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 358 |    822.050462 |     48.429136 | Gabriel Lio, vectorized by Zimices                                                                                                                                                   |
| 359 |    649.509611 |    776.132192 | Matt Crook                                                                                                                                                                           |
| 360 |    495.981858 |    554.376298 | Gareth Monger                                                                                                                                                                        |
| 361 |    469.239999 |    336.859662 | NA                                                                                                                                                                                   |
| 362 |    551.688194 |      7.398662 | Jagged Fang Designs                                                                                                                                                                  |
| 363 |    459.365639 |    341.755745 | Mathilde Cordellier                                                                                                                                                                  |
| 364 |     99.248693 |     14.377225 | Margot Michaud                                                                                                                                                                       |
| 365 |    222.182156 |     17.316500 | Zimices                                                                                                                                                                              |
| 366 |    326.584041 |     25.291024 | Anthony Caravaggi                                                                                                                                                                    |
| 367 |    911.781548 |    444.349124 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 368 |    439.668829 |     15.838142 | NA                                                                                                                                                                                   |
| 369 |    793.832221 |    779.275969 | Birgit Lang                                                                                                                                                                          |
| 370 |    467.706340 |    433.867278 | Sarah Werning                                                                                                                                                                        |
| 371 |    309.805949 |    522.519978 | NA                                                                                                                                                                                   |
| 372 |    963.111387 |     81.530870 | NA                                                                                                                                                                                   |
| 373 |     47.152189 |     63.333057 | Jagged Fang Designs                                                                                                                                                                  |
| 374 |    494.524661 |    735.748778 | Matt Crook                                                                                                                                                                           |
| 375 |   1005.447811 |    285.414112 | Matt Martyniuk                                                                                                                                                                       |
| 376 |      7.148603 |    625.624180 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                          |
| 377 |    758.465064 |    128.771490 | Matt Crook                                                                                                                                                                           |
| 378 |   1014.730172 |    420.301087 | Adrian Reich                                                                                                                                                                         |
| 379 |     19.716687 |    352.200831 | Julio Garza                                                                                                                                                                          |
| 380 |    309.176122 |    459.183768 | Scott Hartman                                                                                                                                                                        |
| 381 |   1006.000089 |    486.538306 | Tracy A. Heath                                                                                                                                                                       |
| 382 |    659.204564 |    306.095017 | Birgit Lang                                                                                                                                                                          |
| 383 |    674.926674 |    719.832701 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 384 |    638.413122 |    215.967368 | Chris huh                                                                                                                                                                            |
| 385 |    717.052736 |    515.191523 | Margot Michaud                                                                                                                                                                       |
| 386 |    756.244937 |    277.104317 | Matt Crook                                                                                                                                                                           |
| 387 |    653.853234 |     40.433304 | Jagged Fang Designs                                                                                                                                                                  |
| 388 |    924.910808 |    100.503811 | Margot Michaud                                                                                                                                                                       |
| 389 |    238.133292 |     14.348614 | Katie S. Collins                                                                                                                                                                     |
| 390 |    952.456472 |    158.206795 | Chase Brownstein                                                                                                                                                                     |
| 391 |    209.906555 |    450.534204 | Scott Hartman                                                                                                                                                                        |
| 392 |    998.263370 |    456.459415 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 393 |    491.260203 |    100.118313 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 394 |    925.245280 |    665.298751 | Zimices                                                                                                                                                                              |
| 395 |    108.809954 |    408.814072 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                                          |
| 396 |    318.845207 |    250.348953 | Zimices                                                                                                                                                                              |
| 397 |    646.729368 |    563.822701 | Zimices                                                                                                                                                                              |
| 398 |    671.565759 |     28.698870 | Rachel Shoop                                                                                                                                                                         |
| 399 |    310.662368 |    722.588336 | Ferran Sayol                                                                                                                                                                         |
| 400 |    221.691339 |    358.322668 | Chris huh                                                                                                                                                                            |
| 401 |    126.442422 |    226.760759 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 402 |    255.320405 |    325.857219 | Tasman Dixon                                                                                                                                                                         |
| 403 |    989.562380 |    104.223666 | Roger Witter, vectorized by Zimices                                                                                                                                                  |
| 404 |    304.355869 |    669.996201 | Rebecca Groom                                                                                                                                                                        |
| 405 |    633.629963 |    297.257238 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
| 406 |    312.197889 |    225.495322 | Collin Gross                                                                                                                                                                         |
| 407 |    966.377727 |     25.171252 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
| 408 |    877.120702 |    620.807389 | Crystal Maier                                                                                                                                                                        |
| 409 |    772.712932 |    631.389392 | Ferran Sayol                                                                                                                                                                         |
| 410 |    985.175777 |     17.222180 | Zimices                                                                                                                                                                              |
| 411 |     74.446428 |    411.331532 | NA                                                                                                                                                                                   |
| 412 |    508.943078 |    743.178493 | NA                                                                                                                                                                                   |
| 413 |    942.618457 |    200.360495 | Steven Traver                                                                                                                                                                        |
| 414 |    415.835152 |    312.691941 | NA                                                                                                                                                                                   |
| 415 |    416.134618 |    650.448417 | Joanna Wolfe                                                                                                                                                                         |
| 416 |    987.162391 |    743.988571 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                          |
| 417 |    694.582577 |    755.197266 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                               |
| 418 |    368.860824 |    773.126113 | Beth Reinke                                                                                                                                                                          |
| 419 |    788.136921 |    559.998384 | Scott Hartman                                                                                                                                                                        |
| 420 |    975.794503 |    473.950887 | Tasman Dixon                                                                                                                                                                         |
| 421 |    194.597694 |    732.936385 | Chris huh                                                                                                                                                                            |
| 422 |   1011.053221 |     65.133972 | Kamil S. Jaron                                                                                                                                                                       |
| 423 |   1018.761526 |    207.489877 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 424 |    986.329187 |    432.210053 | Jagged Fang Designs                                                                                                                                                                  |
| 425 |    500.739601 |    364.885340 | Gopal Murali                                                                                                                                                                         |
| 426 |   1008.331250 |    236.982579 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                                          |
| 427 |    422.427170 |    533.211398 | Steven Traver                                                                                                                                                                        |
| 428 |     81.660067 |    435.053291 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                                                     |
| 429 |    791.187736 |    725.714609 | Chris huh                                                                                                                                                                            |
| 430 |    844.483430 |    704.533190 | Alex Slavenko                                                                                                                                                                        |
| 431 |    592.172665 |    789.481321 | Christoph Schomburg                                                                                                                                                                  |
| 432 |    993.663814 |    752.494708 | Matt Crook                                                                                                                                                                           |
| 433 |    199.512796 |    435.273651 | Scott Hartman                                                                                                                                                                        |
| 434 |    159.565541 |    385.274378 | Margot Michaud                                                                                                                                                                       |
| 435 |    689.327504 |    227.677761 | Matt Crook                                                                                                                                                                           |
| 436 |    464.634196 |    384.961378 | Zimices                                                                                                                                                                              |
| 437 |    391.183159 |    226.833016 | Caleb M. Gordon                                                                                                                                                                      |
| 438 |    440.493866 |    339.540712 | Tasman Dixon                                                                                                                                                                         |
| 439 |    177.569904 |     74.252061 | FJDegrange                                                                                                                                                                           |
| 440 |    202.228771 |    180.982699 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 441 |    727.770240 |    434.154920 | Christoph Schomburg                                                                                                                                                                  |
| 442 |    763.262135 |    156.902319 | Matt Crook                                                                                                                                                                           |
| 443 |    552.286010 |    249.898624 | Anthony Caravaggi                                                                                                                                                                    |
| 444 |    580.741821 |    517.695895 | Matt Wilkins                                                                                                                                                                         |
| 445 |    315.134472 |     81.615998 | Jiekun He                                                                                                                                                                            |
| 446 |    519.618222 |    477.870153 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                            |
| 447 |    895.993060 |    157.336774 | Felix Vaux                                                                                                                                                                           |
| 448 |    877.851788 |    521.699871 | Amanda Katzer                                                                                                                                                                        |
| 449 |    188.722709 |     17.420249 | Matt Crook                                                                                                                                                                           |
| 450 |    398.996196 |    298.035072 | Zimices                                                                                                                                                                              |
| 451 |    352.641866 |    366.340501 | Scott Hartman                                                                                                                                                                        |
| 452 |    788.265946 |    185.034290 | Matt Crook                                                                                                                                                                           |
| 453 |    357.676897 |    263.026641 | Zimices                                                                                                                                                                              |
| 454 |    454.256325 |    488.044165 | Sarah Werning                                                                                                                                                                        |
| 455 |    360.412864 |    530.427325 | NA                                                                                                                                                                                   |
| 456 |    372.245924 |    131.999617 | Margot Michaud                                                                                                                                                                       |
| 457 |      9.448278 |    176.659572 | Martin R. Smith                                                                                                                                                                      |
| 458 |    285.883361 |    205.594243 | Rebecca Groom                                                                                                                                                                        |
| 459 |    360.555312 |    741.273202 | Zimices                                                                                                                                                                              |
| 460 |    371.608764 |    731.013712 | Kailah Thorn & Ben King                                                                                                                                                              |
| 461 |      6.102696 |    784.171682 | Smith609 and T. Michael Keesey                                                                                                                                                       |
| 462 |    896.987574 |    469.202256 | Collin Gross                                                                                                                                                                         |
| 463 |    303.542366 |    155.167822 | Zimices                                                                                                                                                                              |
| 464 |    905.218569 |    616.031619 | Gareth Monger                                                                                                                                                                        |
| 465 |    194.353296 |    747.568983 | Melissa Broussard                                                                                                                                                                    |
| 466 |    351.121860 |    775.370880 | Jonathan Wells                                                                                                                                                                       |
| 467 |    986.407803 |    413.420040 | CNZdenek                                                                                                                                                                             |
| 468 |    950.559166 |    105.197571 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 469 |    290.078347 |    779.109309 | Jagged Fang Designs                                                                                                                                                                  |
| 470 |    689.301188 |    797.765762 | Scott Hartman                                                                                                                                                                        |
| 471 |    606.581226 |    651.324643 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 472 |    951.636832 |    445.369987 | Michele Tobias                                                                                                                                                                       |
| 473 |    940.929517 |    624.534045 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 474 |    779.984871 |    693.328107 | Mason McNair                                                                                                                                                                         |
| 475 |     32.712838 |     90.458949 | L. Shyamal                                                                                                                                                                           |
| 476 |    257.096777 |    151.614401 | Caleb M. Brown                                                                                                                                                                       |
| 477 |     73.975325 |    771.951229 | FunkMonk                                                                                                                                                                             |
| 478 |    407.002083 |    544.809386 | Mathieu Basille                                                                                                                                                                      |
| 479 |    986.214119 |    328.629628 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                         |
| 480 |    420.523480 |    773.552266 | Birgit Lang                                                                                                                                                                          |
| 481 |    582.735499 |    773.005644 | T. Michael Keesey (after James & al.)                                                                                                                                                |
| 482 |    133.210219 |    503.024789 | Matt Crook                                                                                                                                                                           |
| 483 |    942.177024 |    607.398744 | T. Michael Keesey                                                                                                                                                                    |
| 484 |    476.555340 |    568.152109 | FunkMonk (Michael B. H.)                                                                                                                                                             |
| 485 |     56.681312 |    429.316240 | Scott Hartman                                                                                                                                                                        |
| 486 |    909.419758 |    599.372908 | Birgit Lang                                                                                                                                                                          |
| 487 |    923.418567 |    522.822146 | Chris huh                                                                                                                                                                            |
| 488 |    545.955243 |    243.095404 | NA                                                                                                                                                                                   |
| 489 |    837.991061 |     43.962033 | Tracy A. Heath                                                                                                                                                                       |
| 490 |    497.183262 |    456.862770 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                                              |
| 491 |    117.238435 |    199.113001 | Jaime Headden                                                                                                                                                                        |
| 492 |    965.566368 |    603.636211 | T. Michael Keesey                                                                                                                                                                    |
| 493 |     22.171114 |    402.171812 | T. Michael Keesey                                                                                                                                                                    |
| 494 |    300.282819 |     32.499300 | Christine Axon                                                                                                                                                                       |
| 495 |    143.745709 |    700.788236 | Gareth Monger                                                                                                                                                                        |
| 496 |    480.892856 |    140.212424 | Chase Brownstein                                                                                                                                                                     |
| 497 |    301.196574 |    280.941535 | Matt Crook                                                                                                                                                                           |
| 498 |    257.203599 |    524.731509 | Zimices                                                                                                                                                                              |
| 499 |    302.365861 |    260.005538 | Pete Buchholz                                                                                                                                                                        |
| 500 |    921.495159 |    766.639749 | Margot Michaud                                                                                                                                                                       |
| 501 |    265.041707 |    779.693477 | Mathieu Basille                                                                                                                                                                      |
| 502 |    149.085206 |      7.648218 | Zimices                                                                                                                                                                              |
| 503 |    574.053665 |    790.605514 | Renato Santos                                                                                                                                                                        |
| 504 |    374.613232 |    235.683502 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 505 |    246.992740 |    117.130970 | NA                                                                                                                                                                                   |
| 506 |    910.463726 |    680.722237 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 507 |    441.600396 |    252.413116 | Gareth Monger                                                                                                                                                                        |
| 508 |     76.722176 |    351.115998 | Katie S. Collins                                                                                                                                                                     |
| 509 |    501.351141 |    372.450264 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                         |
| 510 |     48.167087 |     30.447008 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                         |
| 511 |    181.921323 |    186.827857 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 512 |    534.018565 |    762.058688 | Yan Wong                                                                                                                                                                             |
| 513 |    140.590047 |     42.178044 | NA                                                                                                                                                                                   |
| 514 |    712.027963 |    227.083416 | terngirl                                                                                                                                                                             |
| 515 |    533.490949 |    534.940244 | Matt Crook                                                                                                                                                                           |
| 516 |    657.184735 |    581.143528 | Dean Schnabel                                                                                                                                                                        |
| 517 |    318.839648 |    795.411658 | Mo Hassan                                                                                                                                                                            |
| 518 |    390.583936 |     63.310470 | Matt Crook                                                                                                                                                                           |
| 519 |    185.710053 |    523.632336 | Steven Traver                                                                                                                                                                        |
| 520 |   1001.304551 |    165.216656 | Caleb M. Brown                                                                                                                                                                       |
| 521 |    435.754234 |    561.361974 | Alexandra van der Geer                                                                                                                                                               |
| 522 |    656.303746 |    175.840981 | Mathilde Cordellier                                                                                                                                                                  |
| 523 |    142.811844 |    316.758800 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 524 |     13.826587 |    132.951929 | Sarah Werning                                                                                                                                                                        |
| 525 |    267.417186 |    258.180200 | Jack Mayer Wood                                                                                                                                                                      |
| 526 |    505.700158 |    756.755289 | Birgit Lang; original image by virmisco.org                                                                                                                                          |
| 527 |   1011.528214 |    545.327601 | NA                                                                                                                                                                                   |
| 528 |    501.447544 |    240.496814 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 529 |      7.617494 |    252.216817 | Tauana J. Cunha                                                                                                                                                                      |
| 530 |    515.732667 |     56.529417 | Chris huh                                                                                                                                                                            |
| 531 |    191.976615 |    193.267348 | Matt Dempsey                                                                                                                                                                         |
| 532 |     57.779835 |    518.003122 | Smith609 and T. Michael Keesey                                                                                                                                                       |
| 533 |    640.656867 |     99.894950 | Christine Axon                                                                                                                                                                       |
| 534 |    952.139416 |      8.027996 | Ferran Sayol                                                                                                                                                                         |
| 535 |    995.146843 |    475.851932 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 536 |    311.475976 |    117.730881 | T. Michael Keesey                                                                                                                                                                    |
| 537 |     32.374524 |    311.890994 | Matt Crook                                                                                                                                                                           |
| 538 |    896.668429 |    480.717981 | Lukasiniho                                                                                                                                                                           |
| 539 |    142.300331 |    747.197072 | NA                                                                                                                                                                                   |
| 540 |    140.670179 |    691.006784 | Margot Michaud                                                                                                                                                                       |
| 541 |    458.681352 |    449.738023 | Rebecca Groom                                                                                                                                                                        |
| 542 |    830.484152 |    630.351867 | Matt Crook                                                                                                                                                                           |
| 543 |     12.916079 |    425.474898 | Matt Crook                                                                                                                                                                           |
| 544 |    100.518136 |    489.419368 | FJDegrange                                                                                                                                                                           |
| 545 |    580.247219 |    462.911569 | Zimices                                                                                                                                                                              |
| 546 |    322.321799 |    517.597669 | Margot Michaud                                                                                                                                                                       |
| 547 |     62.917637 |    486.157653 | Zimices                                                                                                                                                                              |
| 548 |     31.055800 |    619.723052 | Rebecca Groom                                                                                                                                                                        |
| 549 |     28.077393 |    769.450631 | Matt Crook                                                                                                                                                                           |
| 550 |    261.142474 |    406.743899 | Birgit Lang                                                                                                                                                                          |
| 551 |    163.277183 |     71.189430 | Sarah Werning                                                                                                                                                                        |
| 552 |    266.764582 |    472.950564 | Birgit Lang                                                                                                                                                                          |
| 553 |    777.393797 |    501.712417 | Matt Crook                                                                                                                                                                           |
| 554 |   1005.764014 |    134.867424 | Zimices                                                                                                                                                                              |
| 555 |    943.913067 |    632.443976 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 556 |    826.317934 |    273.367106 | Ferran Sayol                                                                                                                                                                         |
| 557 |    719.819380 |    787.761019 | Ferran Sayol                                                                                                                                                                         |
| 558 |    584.848247 |     75.710021 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 559 |    595.211333 |    656.714165 | Zimices                                                                                                                                                                              |
| 560 |    953.696455 |    665.012059 | Becky Barnes                                                                                                                                                                         |
| 561 |    115.874363 |    284.895124 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                       |
| 562 |    469.077681 |    697.670141 | Gareth Monger                                                                                                                                                                        |
| 563 |     92.848168 |    723.297282 | CNZdenek                                                                                                                                                                             |
| 564 |   1000.830112 |     90.503089 | NA                                                                                                                                                                                   |
| 565 |    894.951587 |    296.214063 | nicubunu                                                                                                                                                                             |
| 566 |    618.446836 |    246.047865 | Cesar Julian                                                                                                                                                                         |
| 567 |    565.023537 |    682.832587 | NA                                                                                                                                                                                   |
| 568 |    553.341527 |    374.235406 | Steven Traver                                                                                                                                                                        |
| 569 |    869.609413 |    344.554974 | Margot Michaud                                                                                                                                                                       |
| 570 |    698.807276 |    509.555095 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 571 |    886.559773 |    254.545228 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 572 |     10.336220 |    299.594028 | Matt Crook                                                                                                                                                                           |
| 573 |    718.298618 |    449.654839 | Aadx                                                                                                                                                                                 |
| 574 |   1013.662735 |    156.396182 | Maija Karala                                                                                                                                                                         |
| 575 |    720.148973 |    550.816209 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                               |
| 576 |    952.299900 |    469.313942 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 577 |    677.515470 |    791.935438 | Chris huh                                                                                                                                                                            |
| 578 |    472.344881 |    624.569629 | Ferran Sayol                                                                                                                                                                         |
| 579 |    409.142179 |    528.330215 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 580 |    183.538418 |    461.855688 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                                              |
| 581 |    848.050524 |     41.833156 | Alexandre Vong                                                                                                                                                                       |
| 582 |     22.077587 |    581.861915 | Matt Crook                                                                                                                                                                           |
| 583 |    544.766223 |    382.523515 | NA                                                                                                                                                                                   |
| 584 |    946.789778 |    206.541863 | Tasman Dixon                                                                                                                                                                         |
| 585 |    322.074185 |    667.334095 | NA                                                                                                                                                                                   |
| 586 |    317.998228 |    328.011125 | Mo Hassan                                                                                                                                                                            |
| 587 |    646.799034 |     93.252512 | Ferran Sayol                                                                                                                                                                         |
| 588 |    186.418436 |     90.248354 | Chase Brownstein                                                                                                                                                                     |
| 589 |    110.250194 |    308.196326 | Steven Traver                                                                                                                                                                        |
| 590 |    183.281832 |    216.429585 | Ferran Sayol                                                                                                                                                                         |
| 591 |    577.649961 |    746.488932 | Margot Michaud                                                                                                                                                                       |
| 592 |     34.105233 |    415.128399 | Mykle Hoban                                                                                                                                                                          |
| 593 |    602.095703 |    154.411920 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 594 |    365.604097 |    785.986750 | Margot Michaud                                                                                                                                                                       |
| 595 |    171.461485 |    756.237392 | Ferran Sayol                                                                                                                                                                         |
| 596 |    614.197617 |      4.097208 | Scott Hartman                                                                                                                                                                        |
| 597 |   1016.097311 |    500.662641 | Matt Crook                                                                                                                                                                           |
| 598 |    688.975413 |    580.430566 | Christoph Schomburg                                                                                                                                                                  |
| 599 |     30.467734 |    298.270221 | Ferran Sayol                                                                                                                                                                         |
| 600 |    321.266483 |    771.252667 | Scott Hartman                                                                                                                                                                        |
| 601 |    698.861796 |    474.780040 | CNZdenek                                                                                                                                                                             |
| 602 |    224.105221 |    133.426064 | Margot Michaud                                                                                                                                                                       |
| 603 |    946.229846 |    493.049336 | Gareth Monger                                                                                                                                                                        |
| 604 |    288.651740 |    350.489718 | M Kolmann                                                                                                                                                                            |
| 605 |    233.727734 |    461.046073 | Margot Michaud                                                                                                                                                                       |
| 606 |    698.029142 |    576.298377 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
| 607 |    524.372783 |      9.786460 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                                        |
| 608 |    382.328668 |     58.843402 | L. Shyamal                                                                                                                                                                           |
| 609 |    364.389754 |    343.306763 | Rainer Schoch                                                                                                                                                                        |
| 610 |    357.943990 |    149.174712 | Ingo Braasch                                                                                                                                                                         |
| 611 |    779.741845 |    203.993214 | Jiekun He                                                                                                                                                                            |
| 612 |    846.037353 |    534.432166 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                     |
| 613 |    642.625945 |    716.029136 | Margot Michaud                                                                                                                                                                       |
| 614 |    734.562631 |    445.621755 | SecretJellyMan                                                                                                                                                                       |
| 615 |    807.992420 |    533.404895 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 616 |    385.683812 |    176.758112 | Chris huh                                                                                                                                                                            |
| 617 |    387.276204 |     15.553723 | Dmitry Bogdanov                                                                                                                                                                      |
| 618 |    986.514702 |    512.506817 | Matt Crook                                                                                                                                                                           |
| 619 |   1004.733774 |     32.879906 | T. Michael Keesey (after Heinrich Harder)                                                                                                                                            |
| 620 |    233.483581 |    780.026629 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 621 |    823.424411 |     64.686577 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
| 622 |    903.686113 |    165.632160 | Melissa Broussard                                                                                                                                                                    |
| 623 |    439.587677 |    382.962373 | Dean Schnabel                                                                                                                                                                        |
| 624 |     54.764607 |    705.495140 | Cesar Julian                                                                                                                                                                         |
| 625 |    708.725353 |    631.638855 | Ferran Sayol                                                                                                                                                                         |
| 626 |    866.209949 |    313.252829 | Javier Luque                                                                                                                                                                         |
| 627 |    404.018623 |    512.779451 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                                |
| 628 |    862.298630 |      9.210158 | Shyamal                                                                                                                                                                              |
| 629 |    757.092237 |    439.870856 | L. Shyamal                                                                                                                                                                           |
| 630 |    463.557676 |     74.208569 | Emily Willoughby                                                                                                                                                                     |
| 631 |    811.748883 |    305.369219 | Christoph Schomburg                                                                                                                                                                  |
| 632 |    914.291803 |    393.558336 | Scott Hartman                                                                                                                                                                        |
| 633 |   1016.017328 |    789.363577 | Margot Michaud                                                                                                                                                                       |
| 634 |    135.419820 |    729.002069 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                                      |
| 635 |    295.262636 |    253.363106 | Zimices                                                                                                                                                                              |
| 636 |    274.370258 |    527.092627 | Jagged Fang Designs                                                                                                                                                                  |
| 637 |    146.908550 |    646.391069 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                                          |
| 638 |    650.183582 |    145.293519 | Tasman Dixon                                                                                                                                                                         |
| 639 |    931.671993 |     11.967647 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 640 |    180.231671 |    126.912893 | Melissa Broussard                                                                                                                                                                    |
| 641 |    898.155731 |     71.992880 | Mattia Menchetti                                                                                                                                                                     |
| 642 |    632.282110 |    571.911959 | Lauren Anderson                                                                                                                                                                      |
| 643 |     61.416636 |    101.893556 | Maija Karala                                                                                                                                                                         |
| 644 |    820.993844 |    609.604863 | Smokeybjb                                                                                                                                                                            |
| 645 |    591.797186 |    774.076988 | Matt Crook                                                                                                                                                                           |
| 646 |    365.177023 |    497.667100 | Chris huh                                                                                                                                                                            |
| 647 |    251.026970 |    207.821637 | Iain Reid                                                                                                                                                                            |
| 648 |    129.593066 |    619.308218 | Jaime Headden                                                                                                                                                                        |
| 649 |    693.200602 |    526.358306 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 650 |    721.215967 |    740.104946 | Jake Warner                                                                                                                                                                          |
| 651 |     75.939232 |    158.711085 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                        |
| 652 |    271.771113 |    156.785964 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                                        |
| 653 |    141.275258 |    192.140293 | Chris huh                                                                                                                                                                            |
| 654 |    805.773964 |    291.582983 | Steven Traver                                                                                                                                                                        |
| 655 |    705.565914 |     67.147185 | Chris huh                                                                                                                                                                            |
| 656 |    445.939953 |    317.910887 | Sarah Werning                                                                                                                                                                        |
| 657 |    884.007826 |    703.938974 | Scott Hartman                                                                                                                                                                        |
| 658 |    259.457880 |    124.858352 | Michelle Site                                                                                                                                                                        |
| 659 |    303.524389 |     49.625921 | Michelle Site                                                                                                                                                                        |
| 660 |    307.596003 |    351.827590 | Emily Willoughby                                                                                                                                                                     |
| 661 |     29.462953 |    253.977898 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 662 |    769.706139 |    670.803303 | Alex Slavenko                                                                                                                                                                        |
| 663 |    263.641657 |    323.033744 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                                    |
| 664 |    558.238620 |    646.062415 | Christoph Schomburg                                                                                                                                                                  |
| 665 |    193.810422 |    131.378399 | Matt Crook                                                                                                                                                                           |
| 666 |    523.346683 |    250.799993 | Zimices                                                                                                                                                                              |
| 667 |    707.326665 |    574.695067 | NA                                                                                                                                                                                   |
| 668 |    843.557008 |    646.846744 | Chris huh                                                                                                                                                                            |
| 669 |    964.101774 |    432.058214 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 670 |    623.442833 |    462.261521 | NA                                                                                                                                                                                   |
| 671 |    255.754332 |    670.883819 | Caio Bernardes, vectorized by Zimices                                                                                                                                                |
| 672 |    103.027024 |    468.409133 | Margot Michaud                                                                                                                                                                       |
| 673 |     73.666720 |    782.295321 | NA                                                                                                                                                                                   |
| 674 |    785.821422 |    484.869574 | Margot Michaud                                                                                                                                                                       |
| 675 |    888.198005 |    378.775346 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                                    |
| 676 |    114.821272 |     61.508811 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                                |
| 677 |    580.760579 |    566.313326 | Lukasiniho                                                                                                                                                                           |
| 678 |    720.646403 |    642.466244 | Tasman Dixon                                                                                                                                                                         |
| 679 |    998.331762 |    117.502105 | Steven Traver                                                                                                                                                                        |
| 680 |     23.660809 |    168.690735 | Joanna Wolfe                                                                                                                                                                         |
| 681 |    587.088272 |     19.440824 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 682 |    464.602136 |    164.190050 | Steven Traver                                                                                                                                                                        |
| 683 |    342.448174 |    465.521821 | Zimices                                                                                                                                                                              |
| 684 |    362.828370 |    506.061573 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 685 |    948.193762 |    177.361774 | Darius Nau                                                                                                                                                                           |
| 686 |     30.802668 |     53.417327 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                                        |
| 687 |    342.951184 |    214.365927 | Michael Scroggie                                                                                                                                                                     |
| 688 |     43.112323 |    392.962248 | wsnaccad                                                                                                                                                                             |
| 689 |    492.798772 |    111.440116 | Ferran Sayol                                                                                                                                                                         |
| 690 |    993.898359 |    466.251349 | Zimices                                                                                                                                                                              |
| 691 |    498.204484 |    656.863578 | Maija Karala                                                                                                                                                                         |
| 692 |    167.910863 |    354.976012 | Steven Traver                                                                                                                                                                        |
| 693 |    383.969187 |    739.813366 | Margot Michaud                                                                                                                                                                       |
| 694 |    775.558576 |    293.911162 | Margot Michaud                                                                                                                                                                       |
| 695 |     42.371474 |    127.772849 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 696 |    792.276775 |    223.082155 | Katie S. Collins                                                                                                                                                                     |
| 697 |    768.040826 |    646.682038 | Zimices                                                                                                                                                                              |
| 698 |    879.269086 |     14.809460 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                                     |
| 699 |    281.611566 |    250.067253 | Scott Hartman                                                                                                                                                                        |
| 700 |    885.279179 |    630.630697 | xgirouxb                                                                                                                                                                             |
| 701 |    313.519325 |    138.745390 | Matt Crook                                                                                                                                                                           |
| 702 |    851.356645 |    557.663474 | Zimices                                                                                                                                                                              |
| 703 |    408.503938 |    341.850831 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 704 |    287.272137 |    476.015429 | Michael Scroggie                                                                                                                                                                     |
| 705 |    446.425803 |    794.734197 | Sarah Werning                                                                                                                                                                        |
| 706 |    562.193548 |    766.055707 | Cesar Julian                                                                                                                                                                         |
| 707 |    604.758494 |    766.447722 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 708 |    888.453521 |    335.294802 | Ferran Sayol                                                                                                                                                                         |
| 709 |    999.229503 |    627.529916 | Joanna Wolfe                                                                                                                                                                         |
| 710 |    745.003392 |    650.479781 | Julio Garza                                                                                                                                                                          |
| 711 |    644.194603 |    221.725728 | Lukas Panzarin                                                                                                                                                                       |
| 712 |    488.335494 |      2.583429 | Emily Willoughby                                                                                                                                                                     |
| 713 |    993.154383 |    173.099353 | T. Michael Keesey                                                                                                                                                                    |
| 714 |    596.404264 |    754.537504 | Gareth Monger                                                                                                                                                                        |
| 715 |     17.336814 |    416.117350 | T. Michael Keesey                                                                                                                                                                    |
| 716 |    631.941974 |    467.901947 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                                      |
| 717 |    325.142178 |    455.922490 | Dean Schnabel                                                                                                                                                                        |
| 718 |    339.000481 |    225.892370 | Steven Traver                                                                                                                                                                        |
| 719 |    282.448832 |    467.196004 | Tasman Dixon                                                                                                                                                                         |
| 720 |    393.925810 |     55.858375 | Chris huh                                                                                                                                                                            |
| 721 |    874.201786 |    793.683505 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                         |
| 722 |    556.907212 |     49.865415 | Rebecca Groom                                                                                                                                                                        |
| 723 |     12.831997 |    665.607359 | Oscar Sanisidro                                                                                                                                                                      |
| 724 |    861.633530 |     35.901111 | Andrew A. Farke                                                                                                                                                                      |
| 725 |    932.636343 |    192.447738 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                       |
| 726 |    802.733751 |    148.007974 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                                      |
| 727 |    962.392215 |    784.484528 | Katie S. Collins                                                                                                                                                                     |
| 728 |    221.998243 |    158.144781 | Zimices                                                                                                                                                                              |
| 729 |     87.801422 |     60.686830 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 730 |    975.513347 |    498.616400 | wsnaccad                                                                                                                                                                             |
| 731 |    721.052226 |    212.236813 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                         |
| 732 |    620.489711 |    156.500026 | T. Michael Keesey                                                                                                                                                                    |
| 733 |    812.847738 |    221.867403 | Felix Vaux                                                                                                                                                                           |
| 734 |    651.176620 |    111.932399 | M Hutchinson                                                                                                                                                                         |
| 735 |    759.340310 |    569.493100 | Michelle Site                                                                                                                                                                        |
| 736 |    103.342320 |     30.326069 | Margot Michaud                                                                                                                                                                       |
| 737 |     14.522450 |    742.201058 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 738 |    746.898388 |    464.508416 | Margot Michaud                                                                                                                                                                       |
| 739 |     19.046252 |    194.157296 | Zimices                                                                                                                                                                              |
| 740 |     17.973197 |    284.963999 | Ferran Sayol                                                                                                                                                                         |
| 741 |    581.098207 |    551.334802 | Ferran Sayol                                                                                                                                                                         |
| 742 |    906.462438 |    697.228881 | Gareth Monger                                                                                                                                                                        |
| 743 |     79.803814 |    148.558725 | S.Martini                                                                                                                                                                            |
| 744 |    218.427281 |    732.558744 | Matt Crook                                                                                                                                                                           |
| 745 |    757.381000 |    169.327918 | NA                                                                                                                                                                                   |
| 746 |    128.843466 |    415.346368 | T. Michael Keesey                                                                                                                                                                    |
| 747 |    387.058015 |    367.815974 | T. Michael Keesey                                                                                                                                                                    |
| 748 |    233.165681 |    389.150999 | Gareth Monger                                                                                                                                                                        |
| 749 |    314.807270 |    422.521658 | Alex Slavenko                                                                                                                                                                        |
| 750 |    450.312628 |     25.967648 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 751 |    389.521785 |     84.467531 | SecretJellyMan                                                                                                                                                                       |
| 752 |    673.065586 |    711.816783 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                                             |
| 753 |    598.455276 |    168.321141 | Zimices                                                                                                                                                                              |
| 754 |    971.632515 |    104.392254 | Steven Traver                                                                                                                                                                        |
| 755 |    571.841514 |    557.365046 | Zimices                                                                                                                                                                              |
| 756 |    960.977862 |    148.418661 | Scott Hartman                                                                                                                                                                        |
| 757 |    848.037682 |     14.314459 | Matt Crook                                                                                                                                                                           |
| 758 |    240.244462 |    320.639832 | Anthony Caravaggi                                                                                                                                                                    |
| 759 |    101.813540 |    220.138871 | Ferran Sayol                                                                                                                                                                         |
| 760 |     13.221241 |    335.555487 | NA                                                                                                                                                                                   |
| 761 |     41.742722 |    149.332283 | Zimices                                                                                                                                                                              |
| 762 |    410.965340 |    639.678935 | Chris huh                                                                                                                                                                            |
| 763 |    588.620696 |    544.288349 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                                            |
| 764 |    350.629234 |      8.680088 | Margot Michaud                                                                                                                                                                       |
| 765 |    126.118477 |     48.441648 | Cesar Julian                                                                                                                                                                         |
| 766 |    768.773163 |    550.798805 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 767 |    457.139686 |    469.906161 | NA                                                                                                                                                                                   |
| 768 |    295.311007 |    527.990296 | Andrew A. Farke                                                                                                                                                                      |
| 769 |    276.904179 |    298.140651 | Crystal Maier                                                                                                                                                                        |
| 770 |    669.358709 |    297.118741 | Gareth Monger                                                                                                                                                                        |
| 771 |    446.344986 |    237.257459 | Jessica Anne Miller                                                                                                                                                                  |
| 772 |    659.366072 |    101.765752 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                         |
| 773 |    477.882982 |    203.697791 | nicubunu                                                                                                                                                                             |
| 774 |    491.262811 |    475.802176 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 775 |    135.437109 |    488.027289 | Zimices                                                                                                                                                                              |
| 776 |    820.632270 |    553.768040 | Ben Liebeskind                                                                                                                                                                       |
| 777 |    333.404481 |    149.092366 | Melissa Broussard                                                                                                                                                                    |
| 778 |    890.227163 |    793.323628 | Zimices                                                                                                                                                                              |
| 779 |    596.312951 |    568.183822 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                     |
| 780 |    542.052666 |     28.832900 | Michelle Site                                                                                                                                                                        |
| 781 |    398.353353 |     26.440248 | Yan Wong                                                                                                                                                                             |
| 782 |    404.598297 |    533.938559 | Gareth Monger                                                                                                                                                                        |
| 783 |    656.720510 |    457.074099 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                                |
| 784 |    943.577668 |    399.150717 | Joanna Wolfe                                                                                                                                                                         |
| 785 |    463.597924 |    193.641654 | Gareth Monger                                                                                                                                                                        |
| 786 |     87.437533 |    663.442566 | Chris huh                                                                                                                                                                            |
| 787 |    425.116182 |    542.038648 | Pete Buchholz                                                                                                                                                                        |
| 788 |     88.124400 |    337.239185 | Mathew Wedel                                                                                                                                                                         |
| 789 |    970.989387 |    423.818286 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                                    |
| 790 |     42.694402 |    443.795392 | Ferran Sayol                                                                                                                                                                         |
| 791 |    386.729281 |    390.190361 | Ewald Rübsamen                                                                                                                                                                       |
| 792 |   1009.940958 |    568.376352 | Matt Crook                                                                                                                                                                           |
| 793 |    237.028847 |     22.376497 | Noah Schlottman, photo by Adam G. Clause                                                                                                                                             |
| 794 |    251.979583 |    473.807770 | Scott Hartman                                                                                                                                                                        |
| 795 |    421.372811 |    208.059649 | NA                                                                                                                                                                                   |
| 796 |     72.610081 |    718.270446 | Matt Crook                                                                                                                                                                           |
| 797 |    670.539029 |    232.986676 | Scott Hartman                                                                                                                                                                        |
| 798 |   1008.145414 |    448.199639 | CNZdenek                                                                                                                                                                             |
| 799 |    962.042976 |    108.929508 | Margot Michaud                                                                                                                                                                       |
| 800 |    224.330318 |    184.034855 | Oscar Sanisidro                                                                                                                                                                      |
| 801 |    670.140481 |    745.539578 | Xavier Giroux-Bougard                                                                                                                                                                |
| 802 |     74.384749 |    708.222386 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                        |
| 803 |    635.186794 |    497.821100 | Matt Crook                                                                                                                                                                           |
| 804 |    386.393682 |    245.029066 | Christoph Schomburg                                                                                                                                                                  |
| 805 |    977.864544 |    420.620473 | Scott Hartman                                                                                                                                                                        |
| 806 |    175.448577 |    671.043203 | Zimices                                                                                                                                                                              |
| 807 |    499.827629 |    675.717969 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                                      |
| 808 |    473.756004 |    684.531843 | Zimices                                                                                                                                                                              |
| 809 |    594.230900 |     92.535789 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 810 |    161.827799 |      4.868924 | Alex Slavenko                                                                                                                                                                        |
| 811 |    397.716411 |    790.733286 | Darius Nau                                                                                                                                                                           |
| 812 |   1014.668865 |     41.431495 | Steven Traver                                                                                                                                                                        |
| 813 |    110.848288 |    388.096500 | Joanna Wolfe                                                                                                                                                                         |
| 814 |    886.907602 |    552.987078 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                        |
| 815 |    858.454427 |    326.810064 | NA                                                                                                                                                                                   |
| 816 |    903.912317 |    346.357392 | Matt Crook                                                                                                                                                                           |
| 817 |    562.346357 |    759.539299 | Gopal Murali                                                                                                                                                                         |
| 818 |    993.210030 |    554.246985 | Matt Crook                                                                                                                                                                           |
| 819 |    312.101198 |    712.148213 | Kamil S. Jaron                                                                                                                                                                       |
| 820 |    780.244242 |    465.554854 | Margot Michaud                                                                                                                                                                       |
| 821 |    949.725350 |    277.655455 | Xavier Giroux-Bougard                                                                                                                                                                |
| 822 |     69.185610 |    526.168598 | Collin Gross                                                                                                                                                                         |
| 823 |    801.806328 |    198.798031 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                                    |
| 824 |    145.420780 |    710.672240 | Margot Michaud                                                                                                                                                                       |
| 825 |    408.708885 |    772.389946 | Ferran Sayol                                                                                                                                                                         |
| 826 |    925.143570 |    673.417418 | Matt Crook                                                                                                                                                                           |
| 827 |    898.697836 |    459.911571 | Pete Buchholz                                                                                                                                                                        |
| 828 |    910.278910 |     14.903272 | Oren Peles / vectorized by Yan Wong                                                                                                                                                  |
| 829 |    554.655340 |    796.485826 | Tasman Dixon                                                                                                                                                                         |
| 830 |    198.090785 |    161.695878 | Neil Kelley                                                                                                                                                                          |
| 831 |    858.200675 |     26.330006 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 832 |   1014.226046 |    605.521802 | Jagged Fang Designs                                                                                                                                                                  |
| 833 |    278.092437 |    786.555732 | Tauana J. Cunha                                                                                                                                                                      |
| 834 |    169.513380 |     44.968811 | Joanna Wolfe                                                                                                                                                                         |
| 835 |    966.984433 |      5.894675 | Michael Scroggie                                                                                                                                                                     |
| 836 |    853.315422 |    599.396027 | Zimices                                                                                                                                                                              |
| 837 |    424.334829 |    509.581251 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 838 |      8.511181 |    317.587825 | NA                                                                                                                                                                                   |
| 839 |    741.988110 |    140.353350 | Zimices                                                                                                                                                                              |
| 840 |    651.052856 |    785.279119 | Xavier Giroux-Bougard                                                                                                                                                                |
| 841 |    651.621575 |     31.622243 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                               |
| 842 |    984.731328 |    489.676686 | Tasman Dixon                                                                                                                                                                         |
| 843 |    161.882582 |    512.236343 | Michelle Site                                                                                                                                                                        |
| 844 |    187.178279 |    752.837344 | T. Michael Keesey                                                                                                                                                                    |
| 845 |    806.468388 |    130.673940 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                               |
| 846 |    833.064279 |     16.879305 | Melissa Broussard                                                                                                                                                                    |
| 847 |    972.766891 |    793.691201 | Zimices                                                                                                                                                                              |
| 848 |    828.459145 |     76.680685 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 849 |    892.562626 |    538.104125 | www.studiospectre.com                                                                                                                                                                |
| 850 |    201.943576 |    759.174515 | Margot Michaud                                                                                                                                                                       |
| 851 |     29.428249 |    603.624835 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 852 |    925.004383 |    723.037171 | Margot Michaud                                                                                                                                                                       |
| 853 |    734.631382 |    745.381137 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                                           |
| 854 |     38.883181 |     70.802249 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                                 |
| 855 |    909.080939 |    537.716154 | Scott Hartman                                                                                                                                                                        |
| 856 |    108.874191 |    296.372012 | Scott Hartman                                                                                                                                                                        |
| 857 |    428.577587 |    321.569236 | Peileppe                                                                                                                                                                             |
| 858 |    424.041209 |    626.722207 | Margot Michaud                                                                                                                                                                       |
| 859 |    784.364782 |    243.000502 | Sarah Werning                                                                                                                                                                        |
| 860 |    401.216511 |    316.912754 | Tracy A. Heath                                                                                                                                                                       |
| 861 |    368.843196 |    252.448832 | NA                                                                                                                                                                                   |
| 862 |     94.342300 |    416.812719 | Sarah Werning                                                                                                                                                                        |
| 863 |    916.719819 |    359.696974 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 864 |    115.530114 |    783.052115 | Kai R. Caspar                                                                                                                                                                        |
| 865 |    794.768071 |     67.461275 | Jagged Fang Designs                                                                                                                                                                  |
| 866 |    835.268464 |    591.075142 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 867 |    521.487050 |    135.922639 | Steven Traver                                                                                                                                                                        |
| 868 |    943.915991 |    730.329889 | NA                                                                                                                                                                                   |
| 869 |    984.003117 |    405.314422 | Margot Michaud                                                                                                                                                                       |
| 870 |     41.153039 |    539.283161 | Collin Gross                                                                                                                                                                         |
| 871 |    958.002882 |    763.062386 | Michelle Site                                                                                                                                                                        |
| 872 |    696.335578 |    266.761474 | Beth Reinke                                                                                                                                                                          |
| 873 |     34.871798 |     14.799068 | Zimices                                                                                                                                                                              |
| 874 |    214.167851 |    438.090630 | Steven Traver                                                                                                                                                                        |
| 875 |    390.931479 |    500.010021 | Joanna Wolfe                                                                                                                                                                         |
| 876 |    629.180255 |    711.148478 | Melissa Broussard                                                                                                                                                                    |
| 877 |    562.381401 |    515.667293 | Cagri Cevrim                                                                                                                                                                         |
| 878 |    467.610143 |     22.596642 | NA                                                                                                                                                                                   |
| 879 |    173.057720 |    202.514864 | NA                                                                                                                                                                                   |
| 880 |    699.012544 |    559.890753 | Matt Crook                                                                                                                                                                           |
| 881 |    295.034481 |    512.542081 | Ferran Sayol                                                                                                                                                                         |
| 882 |   1000.617730 |    340.683438 | Auckland Museum                                                                                                                                                                      |
| 883 |    234.932738 |    209.993765 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 884 |    869.836042 |    117.210481 | Scott Hartman                                                                                                                                                                        |
| 885 |    297.799447 |     40.285510 | Andrew A. Farke                                                                                                                                                                      |
| 886 |    530.256671 |    379.180022 | Steven Traver                                                                                                                                                                        |
| 887 |     62.448102 |    356.613311 | Ferran Sayol                                                                                                                                                                         |
| 888 |    126.527767 |    301.700891 | Tasman Dixon                                                                                                                                                                         |
| 889 |    727.002094 |    114.207124 | Lily Hughes                                                                                                                                                                          |
| 890 |    453.596876 |    336.912184 | Matt Crook                                                                                                                                                                           |
| 891 |   1004.055228 |    402.837580 | Margot Michaud                                                                                                                                                                       |
| 892 |    219.077715 |    227.375209 | Ferran Sayol                                                                                                                                                                         |
| 893 |    789.256486 |    738.580164 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 894 |    718.343742 |    719.321989 | Armin Reindl                                                                                                                                                                         |
| 895 |    192.837895 |    122.136189 | Arthur S. Brum                                                                                                                                                                       |
| 896 |    232.411403 |    738.035613 | T. Michael Keesey                                                                                                                                                                    |
| 897 |    843.219695 |    637.110381 | Emily Willoughby                                                                                                                                                                     |
| 898 |     34.697174 |    135.924246 | Emily Willoughby                                                                                                                                                                     |
| 899 |    419.863316 |    755.052199 | Michael Scroggie                                                                                                                                                                     |
| 900 |    952.935798 |    216.598479 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 901 |     14.166608 |     18.426384 | Zimices                                                                                                                                                                              |
| 902 |    837.249838 |    281.819591 | Gareth Monger                                                                                                                                                                        |
| 903 |    885.549298 |     69.645953 | Andrew Farke and Joseph Sertich                                                                                                                                                      |
| 904 |    974.927261 |    461.963473 | Iain Reid                                                                                                                                                                            |
| 905 |    635.463268 |    244.361560 | Inessa Voet                                                                                                                                                                          |
| 906 |    153.356652 |    500.577456 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 907 |    907.257402 |    232.185427 | Collin Gross                                                                                                                                                                         |
| 908 |    776.697018 |    514.498941 | Michelle Site                                                                                                                                                                        |
| 909 |    638.896815 |    230.212223 | Oscar Sanisidro                                                                                                                                                                      |
| 910 |    192.524003 |    361.216572 | Kailah Thorn & Ben King                                                                                                                                                              |
| 911 |     61.828014 |    405.795278 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 912 |    551.594642 |    275.897588 | FunkMonk                                                                                                                                                                             |
| 913 |    918.827931 |    617.419461 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                                       |
| 914 |    597.450440 |    796.769046 | T. Michael Keesey                                                                                                                                                                    |
| 915 |    844.910347 |     94.036672 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 916 |    890.256183 |    684.316830 | Matt Martyniuk                                                                                                                                                                       |
| 917 |    850.771677 |    125.460482 | Chris huh                                                                                                                                                                            |
| 918 |    135.000406 |    796.504088 | Mathew Wedel                                                                                                                                                                         |
| 919 |    611.937770 |    276.736361 | NA                                                                                                                                                                                   |
| 920 |    991.580415 |    663.752582 | Jaime Headden                                                                                                                                                                        |
| 921 |    642.153161 |    626.402798 | Steven Traver                                                                                                                                                                        |
| 922 |    208.069370 |    742.768292 | Birgit Lang                                                                                                                                                                          |
| 923 |    793.574128 |    464.835631 | T. Michael Keesey                                                                                                                                                                    |
| 924 |    521.062533 |    124.177671 | Juan Carlos Jerí                                                                                                                                                                     |

    #> Your tweet has been posted!
