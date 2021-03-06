import MetalKit

class MultiscaleView: MTKView {
   var commandQueue: MTLCommandQueue!
   
   // Pipeline state for the `clear_pass` compute kernel
   var clearPass: MTLComputePipelineState!
   
   // Pipeline state for the `update_turing_scale` compute kernel
   var updateTuringScalePass: MTLComputePipelineState!
   
   var applySymmetryPass: MTLComputePipelineState!
   
   // Pipeline state for the `render_grid` compute kernel
   var renderGridPass: MTLComputePipelineState!
   
   var gridBuffer: MTLBuffer!
   var scaleStateBuffers: [MTLBuffer] = []
   
   var scaleConfigs = [
      ScaleConfig(
         activator_radius: 100,
         inhibitor_radius: 200,
         small_amount: 0.05,
         symmetry: 4,
         colour: SIMD4<Float>(
            0.9764,
            0.7333,
            0.9804,
            1
         )
      ),
      ScaleConfig(
         activator_radius: 150,
         inhibitor_radius: 200,
         small_amount: 0.04,
         symmetry: 2,
         colour: SIMD4<Float>(
            113.0 / 255.0,
            237.0 / 255.0,
            242.0 / 255.0,
            1
         )
      ),
      ScaleConfig(
         activator_radius: 30,
         inhibitor_radius: 50,
         small_amount: 0.03,
         symmetry: 1,
         colour: SIMD4<Float>(
            208.0 / 255.0,
            167.0 / 255.0,
            250.0 / 255.0,
            1
         )
      ),
      ScaleConfig(
         activator_radius: 10,
         inhibitor_radius: 50,
         small_amount: 0.02,
         symmetry: 1,
         colour: SIMD4<Float>(
            251.0 / 255.0,
            255.0 / 255.0,
            155.0 / 255.0,
            1
         )
      ),
      ScaleConfig(
         activator_radius: 1,
         inhibitor_radius: 2,
         small_amount: 0.01,
         symmetry: 1,
         colour: SIMD4<Float>(
            181.0 / 255.0,
            252.0 / 255.0,
            184.0 / 255.0,
            1
         )
      ),
   ]
   
   var textureWidth = 0
   var textureHeight = 0
   
   required init(coder: NSCoder) {
      super.init(coder: coder)
      
      // Setting this to false allows us to draw directly to the view's drawable within
      // our compute kernel.
      self.framebufferOnly = false
      
      // Lookup the default GPU device. Enable the discreet GPU if it is not already enabled.
      self.device = MTLCreateSystemDefaultDevice()
      
      // Initialise the queue that is used to send commands to the GPU device.
      self.commandQueue = device?.makeCommandQueue()
      
      let drawable = currentDrawable!
      self.textureWidth = drawable.texture.width * 2
      self.textureHeight = drawable.texture.height * 2
      
      lookupKernels()
      allocateBuffers()
      
      print("Texture: width =", textureWidth, " height =", textureHeight)
   }
   
   func lookupKernels() {
      // Lookup our compute kernel functions
      let library = device?.makeDefaultLibrary()
      let updateTuringScaleKernel = library?.makeFunction(name: "update_turing_scale")
      let applySymmetryToScaleKernel = library?.makeFunction(name: "apply_symmetry_to_scale")
      let renderGridKernel = library?.makeFunction(name: "render_grid")
      let clearKernel = library?.makeFunction(name: "clear_pass")
   
      do {
         clearPass = try device?.makeComputePipelineState(function: clearKernel!)
         updateTuringScalePass = try device?.makeComputePipelineState(function: updateTuringScaleKernel!)
         applySymmetryPass = try device?.makeComputePipelineState(function: applySymmetryToScaleKernel!)
         renderGridPass = try device?.makeComputePipelineState(function: renderGridKernel!)
      } catch let error as NSError {
         print(error)
      }
   }
   
   func allocateBuffers() {
      let pixels = textureWidth * textureHeight
      print("Total Pixels: ", pixels)
      
      // Allocate a state buffer for each cell
      for _ in 0..<scaleConfigs.count {
         let stateBuffer = device?.makeBuffer(
            length: MemoryLayout<ScaleCell>.stride * pixels,
            options: .storageModeManaged
         )
         scaleStateBuffers.append(stateBuffer!)
      }
      
      // Generate the initial values for the grid using random numbers between -1 and 1
      var initial: [Float] = []
      for _ in 0..<pixels {
         let value = Float.random(in: -1..<1)
         initial.append(value)
      }

      gridBuffer = device?.makeBuffer(
         bytes: initial,
         length: MemoryLayout<GridCell>.stride * pixels,
         options: .storageModeManaged
      )
   }
   
   var frameCount = 0
   override func draw(_ dirtyRect: NSRect) {
//      let commandBuffer = commandQueue.makeCommandBuffer()
//      let encoder = commandBuffer?.makeComputeCommandEncoder()
//
//      let drawable = currentDrawable!
//      encoder!.setTexture(drawable.texture, index: 0)
//      encoder!.setTexture(drawable.texture, index: 1)
//      encoder!.setBuffer(gridBuffer, offset: 0, index: 1)
//
//      if(frameCount == 0) {
//         blackScreen()
//      }
//
//      for i in 0..<scaleConfigs.count {
//         encoder!.setBuffer(scaleStateBuffers[i], offset: 0, index: 0)
//
//         var config = scaleConfigs[i]
//         encoder!.setBytes(&config, length: MemoryLayout.size(ofValue: config), index: 2)
//         enqueuePass(encoder: encoder!, pass: updateTuringScalePass)
//      }
//
//      for i in 0..<scaleConfigs.count {
//         encoder!.setBuffer(scaleStateBuffers[i], offset: 0, index: 0)
//
//         var config = scaleConfigs[i]
//         encoder!.setBytes(&config, length: MemoryLayout.size(ofValue: config), index: 2)
//         enqueuePass(encoder: encoder!, pass: applySymmetryPass)
//      }
//
//      encoder!.setBuffer(scaleStateBuffers[0], offset: 0, index: 10)
//      encoder!.setBuffer(scaleStateBuffers[1], offset: 0, index: 11)
//      encoder!.setBuffer(scaleStateBuffers[2], offset: 0, index: 12)
//      encoder!.setBuffer(scaleStateBuffers[3], offset: 0, index: 13)
//      encoder!.setBuffer(scaleStateBuffers[4], offset: 0, index: 14)
//      encoder!.setBytes(&scaleConfigs, length: MemoryLayout<ScaleConfig>.stride * scaleConfigs.count, index: 20)
//      enqueuePass(encoder: encoder!, pass: renderGridPass)
//
//      encoder!.endEncoding()
//      commandBuffer?.present(drawable)
//      commandBuffer?.commit()
//      commandBuffer?.waitUntilCompleted()
      
      if frameCount == 0 {
         blackScreen()
      }
      
      convolutionStateUpdate()
      symmetryStateUpdate()
      renderState()
      
//      if frameCount > 10 {
         let filePath = "/Users/elias.jordan/Desktop/render/frame-" + String(format: "%04d", frameCount) + ".png"
         let url = URL(fileURLWithPath: filePath)
         let tex = currentDrawable!.texture
         writeTexture(tex, url: url)
//      }
 
      frameCount += 1
      print("Completed Frames: ", frameCount)
   }
   
   private func renderState() {
      let commandBuffer = commandQueue.makeCommandBuffer()
      let encoder = commandBuffer?.makeComputeCommandEncoder()
      
      let drawable = currentDrawable!
      encoder!.setTexture(drawable.texture, index: 0)
      encoder!.setTexture(drawable.texture, index: 1)
      encoder!.setBuffer(gridBuffer, offset: 0, index: 1)
      
      encoder!.setBuffer(scaleStateBuffers[0], offset: 0, index: 10)
      encoder!.setBuffer(scaleStateBuffers[1], offset: 0, index: 11)
      encoder!.setBuffer(scaleStateBuffers[2], offset: 0, index: 12)
      encoder!.setBuffer(scaleStateBuffers[3], offset: 0, index: 13)
      encoder!.setBuffer(scaleStateBuffers[4], offset: 0, index: 14)
      encoder!.setBytes(&scaleConfigs, length: MemoryLayout<ScaleConfig>.stride * scaleConfigs.count, index: 20)
      enqueuePass(encoder: encoder!, pass: renderGridPass)
      
      encoder!.endEncoding()
      commandBuffer?.present(drawable)
      commandBuffer?.commit()
      commandBuffer?.waitUntilCompleted()
   }
   
   private func symmetryStateUpdate() {
      let commandBuffer = commandQueue.makeCommandBuffer()
      let encoder = commandBuffer?.makeComputeCommandEncoder()
      
      let drawable = currentDrawable!
      encoder!.setTexture(drawable.texture, index: 0)
      encoder!.setTexture(drawable.texture, index: 1)
      encoder!.setBuffer(gridBuffer, offset: 0, index: 1)
      
      for i in 0..<scaleConfigs.count {
         encoder!.setBuffer(scaleStateBuffers[i], offset: 0, index: 0)
         
         var config = scaleConfigs[i]
         encoder!.setBytes(&config, length: MemoryLayout.size(ofValue: config), index: 2)
         enqueuePass(encoder: encoder!, pass: applySymmetryPass)
      }
      
      encoder!.endEncoding()
      commandBuffer?.commit()
      commandBuffer?.waitUntilCompleted()
   }
   
   private func convolutionStateUpdate() {
      let commandBuffer = commandQueue.makeCommandBuffer()
      let encoder = commandBuffer?.makeComputeCommandEncoder()
      
      let drawable = currentDrawable!
      encoder!.setTexture(drawable.texture, index: 0)
      encoder!.setTexture(drawable.texture, index: 1)
      encoder!.setBuffer(gridBuffer, offset: 0, index: 1)
      
      for i in 0..<scaleConfigs.count {
         encoder!.setBuffer(scaleStateBuffers[i], offset: 0, index: 0)
         
         var config = scaleConfigs[i]
         encoder!.setBytes(&config, length: MemoryLayout.size(ofValue: config), index: 2)
         enqueuePass(encoder: encoder!, pass: updateTuringScalePass)
      }
      
      encoder!.endEncoding()
      commandBuffer?.commit()
      commandBuffer?.waitUntilCompleted()
   }
   
   private func blackScreen() {
      let commandBuffer = commandQueue.makeCommandBuffer()
      let encoder = commandBuffer?.makeComputeCommandEncoder()
      
      let drawable = currentDrawable!
      encoder!.setTexture(drawable.texture, index: 0)
      
      enqueuePass(encoder: encoder!, pass: clearPass)
      
      encoder!.endEncoding()
      commandBuffer?.present(drawable)
      commandBuffer?.commit()
      commandBuffer?.waitUntilCompleted()
   }
   
   private func enqueuePass(encoder: MTLComputeCommandEncoder, pass: MTLComputePipelineState) {
      // Tell the encoder what kernel to run
      encoder.setComputePipelineState(pass)
      
      let tgWidth = pass.threadExecutionWidth
      let tgHeight = pass.maxTotalThreadsPerThreadgroup / tgWidth
      
      // Configure the size of each thread group. This controls how
      // many pixels are processed by the GPU at one time.
      let threadsPerThreadGroup = MTLSize(
         width: tgWidth,
         height: tgHeight,
         depth: 1
      )
      
      // Configure the total number of threads that will need to be run
      // to complete this unit of work. Since there is one thread per pixel
      // we use the drawables texture dimensions.
      let threadsPerGrid = MTLSize(
         width: textureWidth,
         height: textureHeight,
         depth: 1
      )
      
      // Enqueues the compute function along with its parameters
      encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
   }
}
